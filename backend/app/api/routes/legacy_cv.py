import asyncio
from datetime import datetime, timezone
from fastapi import APIRouter, Body, HTTPException, status
from typing import Any, Dict, List
import uuid
import re
from pydantic import BaseModel, Field
from google import genai
from google.genai import types
import json
from app.core.config import settings

router = APIRouter()

client = genai.Client(api_key=settings.GEMINI_API_KEY)

class TailoredBulletOutput(BaseModel):
    original_text: str = Field(description="The exact original bullet point from the resume.")
    tailored_text: str = Field(description="The highly tailored version of the bullet point targeting the JD. Make it sound professional and impactful.")
    is_modified: bool = Field(description="Set to true if you significantly modified the text.")

class TailoredSectionOutput(BaseModel):
    company: str = Field(description="Company name from the original resume")
    role: str = Field(description="Job title/role from the original resume")
    date_range: str = Field(description="Date range from the original resume")
    bullets: List[TailoredBulletOutput] = Field(description="List of tailored bullet points for this role")

class TailoringResult(BaseModel):
    ats_match_score: int = Field(description="Calculated ATS match score between 0 and 100 based on keyword density and alignment.")
    matched_keywords: List[str] = Field(description="Keywords from the JD that are present in the resume.")
    missing_keywords: List[str] = Field(description="Crucial keywords from the JD that are completely missing in the resume.")
    sections: List[TailoredSectionOutput] = Field(description="The tailored work experience sections matching the original resume structure.")

FALLBACK_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash']

def _call_gemini_sync(prompt: str) -> str:
    last_error = None
    for model_name in FALLBACK_MODELS:
        for attempt in range(2):
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=TailoringResult,
                        temperature=0.7,
                    ),
                )
                if response.text and response.text.strip():
                    return response.text
            except Exception as e:
                last_error = e
                err_msg = str(e)
                print(f"[Gemini CV Fallback] Model '{model_name}' attempt {attempt + 1} failed: {err_msg}")
                if "503" in err_msg or "high demand" in err_msg.lower() or "429" in err_msg:
                    import time
                    time.sleep(1.0)
                    continue
                else:
                    break
    if last_error:
        raise last_error
    return ""

@router.post("/generate-cv")
async def generate_cv(payload: Dict[Any, Any] = Body(...)):
    job_title = str(payload.get("job_title") or "Target Role")
    target_company = str(payload.get("target_company") or "Target Company")
    user_profile_data = str(payload.get("user_profile_data") or "")
    raw_jd = str(payload.get("raw_jd") or "")
    tone = str(payload.get("tone") or "Professional")

    name_match = re.search(r"Name:\s*(.*)", user_profile_data)
    candidate_name = name_match.group(1).strip() if name_match else "Candidate"
    
    bio_match = re.search(r"Bio:\s*(.*)", user_profile_data)
    bio = bio_match.group(1).strip() if bio_match else ""
    
    edu_match = re.search(r"Education:\s*(.*)", user_profile_data)
    education = edu_match.group(1).strip() if edu_match else ""

    prompt = f"""
    You are an expert ATS optimizer and executive resume writer. 
    Your goal is to tailor the candidate's work experiences to perfectly align with the target Job Description (JD).
    
    Target Company: {target_company}
    Target Role: {job_title}
    Requested Tone: {tone}
    
    ### Candidate Profile Facts:
    {user_profile_data}
    
    ### Target Job Description:
    {raw_jd}
    
    Instructions:
    1. Analyze the candidate's existing work experiences and the JD.
    2. Extract key ATS keywords from the JD.
    3. Identify which keywords the candidate already has (matched) and which are missing.
    4. Calculate a realistic ATS match score (0-100) based on alignment.
    5. For each work experience section in the candidate profile, rewrite the bullet points to highlight skills and achievements relevant to the JD, while keeping the core truth intact. Adopt the requested tone.
    6. Ensure every single original experience section and bullet point is accounted for.
    """
    
    try:
        raw_text = await asyncio.to_thread(_call_gemini_sync, prompt)
        if not raw_text.strip():
            raise ValueError("Empty response from AI model")
        result_data = json.loads(raw_text)
    except Exception as e:
        print(f"Error calling Gemini for CV tailoring: {e}")
        # Graceful fallback result instead of crashing 500
        result_data = {
            "ats_match_score": 50,
            "matched_keywords": [],
            "missing_keywords": [],
            "sections": []
        }
    
    # Reconstruct frontend payload format
    sections = []
    for sec in result_data.get("sections", []):
        bullets = []
        for b in sec.get("bullets", []):
            bullets.append({
                "id": f"tb_{uuid.uuid4().hex[:8]}",
                "original_text": b.get("original_text", ""),
                "tailored_text": b.get("tailored_text", ""),
                "is_modified": b.get("is_modified", True),
                "is_approved": False
            })
        sections.append({
            "company": sec.get("company", ""),
            "role": sec.get("role", ""),
            "date_range": sec.get("date_range", ""),
            "bullets": bullets
        })
        
    return {
        "id": f"app_{uuid.uuid4().hex[:8]}",
        "candidate_name": candidate_name,
        "job_title": job_title,
        "target_company": target_company,
        "tone": tone,
        "bio": bio,
        "education": education,
        "ats_match_score": int(result_data.get("ats_match_score", 50)),
        "matched_keywords": result_data.get("matched_keywords", []),
        "missing_keywords": result_data.get("missing_keywords", []),
        "sections": sections,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
