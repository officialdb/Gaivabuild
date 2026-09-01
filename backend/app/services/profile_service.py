import asyncio
import io
import json
import uuid
from urllib.parse import urlparse
from fastapi import HTTPException, status
import fitz  # PyMuPDF
from docx import Document
from google import genai
from google.genai import types
from pydantic import BaseModel, Field
from typing import List, Optional
from sqlalchemy.future import select
from app.models.profile import MasterProfile
from app.core.config import settings

client = genai.Client(api_key=settings.GEMINI_API_KEY)

class ExtractedBullet(BaseModel):
    id: str = Field(default_factory=lambda: f"blt_{uuid.uuid4().hex[:8]}")
    text: str

class ExtractedExperience(BaseModel):
    id: str = Field(default_factory=lambda: f"exp_{uuid.uuid4().hex[:8]}")
    company: str
    title: str
    start_date: str
    end_date: str
    bullets: List[ExtractedBullet]

class ExtractedEducation(BaseModel):
    id: str = Field(default_factory=lambda: f"edu_{uuid.uuid4().hex[:8]}")
    institution: str
    degree: str
    field_of_study: str
    start_year: str
    end_year: str

class ExtractedSkill(BaseModel):
    id: str = Field(default_factory=lambda: f"skl_{uuid.uuid4().hex[:8]}")
    name: str

class MasterProfileExtraction(BaseModel):
    full_name: str
    title: str
    email: str
    phone: str
    location: str
    bio: str
    experiences: List[ExtractedExperience]
    education: List[ExtractedEducation]
    skills: List[ExtractedSkill]

FALLBACK_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash']

def _call_gemini_extraction_sync(prompt: str) -> str:
    last_error = None
    for model_name in FALLBACK_MODELS:
        for attempt in range(2):
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=MasterProfileExtraction,
                        temperature=0.1,
                    ),
                )
                if response.text and response.text.strip():
                    return response.text
            except Exception as e:
                last_error = e
                err_msg = str(e)
                print(f"[Gemini Fallback] Model '{model_name}' attempt {attempt + 1} failed: {err_msg}")
                if "503" in err_msg or "high demand" in err_msg.lower() or "429" in err_msg:
                    import time
                    time.sleep(1.0)
                    continue
                else:
                    break
    if last_error:
        raise last_error
    return ""

class ProfileService:
    @staticmethod
    async def get_or_create_profile(db, user_id: str) -> MasterProfile:
        result = await db.execute(select(MasterProfile).where(MasterProfile.user_email == user_id))
        profile = result.scalars().first()
        if not profile:
            profile = MasterProfile(
                user_email=user_id,
                full_name="Candidate",
                title="",
                email=user_id,
                phone="",
                location="",
                bio="",
                linkedin_url="",
                github_url="",
                portfolio_url="",
                experiences=[],
                education=[],
                skills=[]
            )
            db.add(profile)
            await db.commit()
            await db.refresh(profile)
        return profile

    @staticmethod
    async def get_full_profile(db, user_id: str):
        result = await db.execute(select(MasterProfile).where(MasterProfile.user_email == user_id))
        profile = result.scalars().first()
        if not profile:
            return {
                "id": user_id,
                "full_name": "",
                "title": "",
                "email": user_id,
                "phone": "",
                "location": "",
                "bio": "",
                "linkedin_url": "",
                "github_url": "",
                "portfolio_url": "",
                "experiences": [],
                "education": [],
                "skills": []
            }
        
        return {
            "id": profile.id,
            "full_name": profile.full_name or "",
            "title": profile.title or "",
            "email": profile.email or user_id,
            "phone": profile.phone or "",
            "location": profile.location or "",
            "bio": profile.bio or "",
            "linkedin_url": profile.linkedin_url or "",
            "github_url": profile.github_url or "",
            "portfolio_url": profile.portfolio_url or "",
            "experiences": profile.experiences or [],
            "education": profile.education or [],
            "skills": profile.skills or [],
        }

    @staticmethod
    async def update_details(db, user_id: str, data):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        if data.full_name is not None:
            profile.full_name = data.full_name
        if data.title is not None:
            profile.title = data.title
        if data.email is not None:
            profile.email = data.email
        if data.phone is not None:
            profile.phone = data.phone
        if data.location is not None:
            profile.location = data.location
        if data.bio is not None:
            profile.bio = data.bio
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def update_links(db, user_id: str, data):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        if data.linkedin_url is not None:
            profile.linkedin_url = str(data.linkedin_url)
        if data.github_url is not None:
            profile.github_url = str(data.github_url)
        if data.portfolio_url is not None:
            profile.portfolio_url = str(data.portfolio_url)
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def create_experience(db, user_id: str, data):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        current_exps = list(profile.experiences or [])
        new_exp = data.model_dump() if hasattr(data, "model_dump") else data.dict()
        if not new_exp.get("id"):
            new_exp["id"] = f"exp_{uuid.uuid4().hex[:8]}"
        current_exps.append(new_exp)
        profile.experiences = current_exps
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def update_experience(db, user_id: str, exp_id: str, data):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        current_exps = list(profile.experiences or [])
        updated_exps = []
        updated_dict = data.model_dump() if hasattr(data, "model_dump") else data.dict()
        for e in current_exps:
            if e.get("id") == exp_id:
                updated_dict["id"] = exp_id
                updated_exps.append(updated_dict)
            else:
                updated_exps.append(e)
        profile.experiences = updated_exps
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def delete_experience(db, user_id: str, exp_id: str):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        current_exps = list(profile.experiences or [])
        profile.experiences = [e for e in current_exps if e.get("id") != exp_id]
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def update_skills(db, user_id: str, data):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        skills_list = []
        for s in data:
            s_dict = s.model_dump() if hasattr(s, "model_dump") else s.dict() if hasattr(s, "dict") else s
            skills_list.append(s_dict)
        profile.skills = skills_list
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def create_education(db, user_id: str, data):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        current_edu = list(profile.education or [])
        new_edu = data.model_dump() if hasattr(data, "model_dump") else data.dict()
        if not new_edu.get("id"):
            new_edu["id"] = f"edu_{uuid.uuid4().hex[:8]}"
        current_edu.append(new_edu)
        profile.education = current_edu
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def update_education(db, user_id: str, edu_id: str, data):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        current_edu = list(profile.education or [])
        updated_edu = []
        updated_dict = data.model_dump() if hasattr(data, "model_dump") else data.dict()
        for ed in current_edu:
            if ed.get("id") == edu_id:
                updated_dict["id"] = edu_id
                updated_edu.append(updated_dict)
            else:
                updated_edu.append(ed)
        profile.education = updated_edu
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def delete_education(db, user_id: str, edu_id: str):
        profile = await ProfileService.get_or_create_profile(db, user_id)
        current_edu = list(profile.education or [])
        profile.education = [ed for ed in current_edu if ed.get("id") != edu_id]
        await db.commit()
        await db.refresh(profile)
        return await ProfileService.get_full_profile(db, user_id)

    @staticmethod
    async def parse_cv(file_bytes: bytes, filename: str, current_user: str, db) -> dict:
        raw_text = ""
        
        # 1. Extract text based on file format
        safe_filename = (filename or "").lower()
        if safe_filename.endswith('.pdf'):
            try:
                doc = fitz.open(stream=file_bytes, filetype="pdf")
                for page in doc:
                    raw_text += page.get_text("text") + "\n"
            except Exception as e:
                print(f"PyMuPDF error: {e}")
        elif safe_filename.endswith('.docx'):
            try:
                doc = Document(io.BytesIO(file_bytes))
                for para in doc.paragraphs:
                    raw_text += para.text + "\n"
            except Exception as e:
                print(f"python-docx error: {e}")
        else:
            raw_text = file_bytes.decode('utf-8', errors='ignore')
            
        if not raw_text.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Could not extract any readable text from the uploaded document."
            )

        # 2. Call Gemini asynchronously to parse and structure the text
        prompt = f"""
        You are an expert ATS parser. Extract the full profile from this raw resume text.
        Structure the experiences, education, and skills. Be highly accurate.
        If dates are missing, use empty strings. If details are missing, leave them empty.
        
        RAW RESUME TEXT:
        {raw_text[:30000]}
        """
        
        try:
            response_text = await asyncio.to_thread(_call_gemini_extraction_sync, prompt)
            if not response_text.strip():
                raise ValueError("Empty response from extraction model")
            result_data = json.loads(response_text)
        except Exception as e:
            print(f"[Parser Fallback] AI parser unavailable ({e}), using instant local rule-based extractor...")
            result_data = _extract_profile_rule_based(raw_text, current_user)
        
        # 3. Save to database safely without erasing existing data if parse is empty
        profile = await ProfileService.get_or_create_profile(db, current_user)
        profile.email = result_data.get("email") or profile.email
        profile.phone = result_data.get("phone") or profile.phone
        profile.location = result_data.get("location") or profile.location
        profile.bio = result_data.get("bio") or profile.bio
        
        if result_data.get("experiences"):
            profile.experiences = result_data["experiences"]
        if result_data.get("education"):
            profile.education = result_data["education"]
        if result_data.get("skills"):
            profile.skills = result_data["skills"]
            
        await db.commit()
        await db.refresh(profile)
        
        return await ProfileService.get_full_profile(db, current_user)

    @staticmethod
    async def parse_linkedin(url: str, current_user: str, db) -> dict:
        import httpx
        
        # SSRF and URL validation
        parsed_url = urlparse(url)
        if parsed_url.scheme not in ("http", "https") or "linkedin.com" not in parsed_url.netloc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid URL. Please provide a valid public LinkedIn profile URL."
            )
        
        # Guard against private/internal IPs
        hostname = parsed_url.hostname or ""
        if hostname in ("localhost", "127.0.0.1", "0.0.0.0", "169.254.169.254") or hostname.startswith("192.168.") or hostname.startswith("10."):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Restricted destination address."
            )

        html_content = ""
        try:
            async with httpx.AsyncClient() as client_http:
                headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
                response = await client_http.get(url, headers=headers, follow_redirects=True, timeout=12.0)
                html_content = response.text
        except Exception as e:
            print(f"Failed to fetch LinkedIn URL: {e}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Could not reach the LinkedIn profile URL. Ensure the profile is public."
            )
            
        prompt = f'''
        You are an expert ATS parser. Extract the full profile from this raw LinkedIn HTML.
        LinkedIn heavily obfuscates their HTML, so look for JSON-LD scripts or basic text blocks.
        Structure the experiences, education, and skills. Be highly accurate.
        If you hit an Authwall or cannot find data, return empty structures.
        
        RAW HTML:
        {html_content[:30000]}
        '''
        
        try:
            response_text = await asyncio.to_thread(_call_gemini_extraction_sync, prompt)
            if not response_text.strip():
                raise ValueError("Empty response from extraction model")
            result_data = json.loads(response_text)
        except Exception as e:
            print(f"[LinkedIn Fallback] AI parser unavailable ({e}), using instant local rule-based extractor...")
            result_data = _extract_profile_rule_based(html_content, current_user)
        
        # Save to database safely without erasing existing data if parse is empty
        profile = await ProfileService.get_or_create_profile(db, current_user)
        profile.full_name = result_data.get("full_name") or profile.full_name
        profile.title = result_data.get("title") or profile.title
        profile.email = result_data.get("email") or profile.email
        profile.phone = result_data.get("phone") or profile.phone
        profile.location = result_data.get("location") or profile.location
        
        if result_data.get("experiences"):
            profile.experiences = result_data["experiences"]
        if result_data.get("education"):
            profile.education = result_data["education"]
        if result_data.get("skills"):
            profile.skills = result_data["skills"]
            
        await db.commit()
        await db.refresh(profile)
        
        return await ProfileService.get_full_profile(db, current_user)
