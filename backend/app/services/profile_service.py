import io
import json
import uuid
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

class ProfileService:
    @staticmethod
    async def get_full_profile(db, user_id: str):
        result = await db.execute(select(MasterProfile).where(MasterProfile.user_email == user_id))
        profile = result.scalars().first()
        if not profile:
            return {
                "id": user_id,
                "full_name": "",
                "title": "",
                "email": "",
                "phone": "",
                "location": "",
                "bio": "",
                "experiences": [],
                "education": [],
                "skills": []
            }
        
        return {
            "id": profile.id,
            "full_name": profile.full_name,
            "title": profile.title,
            "email": profile.email,
            "phone": profile.phone,
            "location": profile.location,
            "bio": profile.bio,
            "experiences": profile.experiences,
            "education": profile.education,
            "skills": profile.skills,
        }

    @staticmethod
    async def create_experience(db, user_id: str, data):
        pass

    @staticmethod
    async def update_experience(db, user_id: str, exp_id: str, data):
        pass

    @staticmethod
    async def delete_experience(db, user_id: str, exp_id: str):
        pass

    @staticmethod
    async def update_skills(db, user_id: str, data):
        pass

    @staticmethod
    async def create_education(db, user_id: str, data):
        pass

    @staticmethod
    async def update_education(db, user_id: str, edu_id: str, data):
        pass

    @staticmethod
    async def delete_education(db, user_id: str, edu_id: str):
        pass

    @staticmethod
    async def parse_cv(file_bytes: bytes, filename: str, current_user: str, db) -> dict:
        raw_text = ""
        
        # 1. Extract text based on file format
        if filename.lower().endswith('.pdf'):
            try:
                doc = fitz.open(stream=file_bytes, filetype="pdf")
                for page in doc:
                    raw_text += page.get_text("text") + "\n"
            except Exception as e:
                print(f"PyMuPDF error: {e}")
        elif filename.lower().endswith('.docx'):
            try:
                doc = Document(io.BytesIO(file_bytes))
                for para in doc.paragraphs:
                    raw_text += para.text + "\n"
            except Exception as e:
                print(f"python-docx error: {e}")
        else:
            raw_text = file_bytes.decode('utf-8', errors='ignore')
            
        if not raw_text.strip():
            raise Exception("Could not extract any text from the document.")

        # 2. Call Gemini to parse and structure the text
        prompt = f"""
        You are an expert ATS parser. Extract the full profile from this raw resume text.
        Structure the experiences, education, and skills. Be highly accurate.
        If dates are missing, use empty strings. If details are missing, leave them empty.
        
        RAW RESUME TEXT:
        {raw_text[:30000]}
        """
        
        response = client.models.generate_content(
            model='gemini-3.6-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=MasterProfileExtraction,
                temperature=0.1,
            ),
        )
        
        result_data = json.loads(response.text)
        
        # 3. Save to database
        # Check if profile already exists
        existing_result = await db.execute(select(MasterProfile).where(MasterProfile.user_email == current_user))
        profile = existing_result.scalars().first()
        
        if not profile:
            profile = MasterProfile(
                user_email=current_user,
                full_name=result_data.get("full_name", ""),
                title=result_data.get("title", ""),
                email=result_data.get("email", ""),
                phone=result_data.get("phone", ""),
                location=result_data.get("location", ""),
                bio=result_data.get("bio", ""),
                experiences=result_data.get("experiences", []),
                education=result_data.get("education", []),
                skills=result_data.get("skills", [])
            )
            db.add(profile)
        else:
            profile.full_name = result_data.get("full_name", profile.full_name)
            profile.title = result_data.get("title", profile.title)
            profile.email = result_data.get("email", profile.email)
            profile.phone = result_data.get("phone", profile.phone)
            profile.location = result_data.get("location", profile.location)
            profile.bio = result_data.get("bio", profile.bio)
            
            # Merge or overwrite experiences? Overwriting for now as it's a fresh parse
            profile.experiences = result_data.get("experiences", [])
            profile.education = result_data.get("education", [])
            profile.skills = result_data.get("skills", [])
            
        await db.commit()
        await db.refresh(profile)
        
        return await ProfileService.get_full_profile(db, current_user)

    @staticmethod
    async def parse_linkedin(url: str, current_user: str, db) -> dict:
        import httpx
        html_content = ""
        try:
            async with httpx.AsyncClient() as client_http:
                # Disguise as a standard browser to try and bypass basic walls
                headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
                response = await client_http.get(url, headers=headers, follow_redirects=True, timeout=10.0)
                html_content = response.text
        except Exception as e:
            print(f"Failed to fetch LinkedIn URL: {e}")
            raise Exception("Could not fetch the LinkedIn profile.")
            
        prompt = f'''
        You are an expert ATS parser. Extract the full profile from this raw LinkedIn HTML.
        LinkedIn heavily obfuscates their HTML, so look for JSON-LD scripts or basic text blocks.
        Structure the experiences, education, and skills. Be highly accurate.
        If you hit an Authwall or cannot find data, return empty structures.
        
        RAW HTML:
        {html_content[:30000]}
        '''
        
        response = client.models.generate_content(
            model='gemini-3.6-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=MasterProfileExtraction,
                temperature=0.1,
            ),
        )
        
        result_data = json.loads(response.text)
        
        # Save to database
        existing_result = await db.execute(select(MasterProfile).where(MasterProfile.user_email == current_user))
        profile = existing_result.scalars().first()
        
        if not profile:
            profile = MasterProfile(
                user_email=current_user,
                full_name=result_data.get("full_name", ""),
                title=result_data.get("title", ""),
                email=result_data.get("email", ""),
                phone=result_data.get("phone", ""),
                location=result_data.get("location", ""),
                bio=result_data.get("bio", ""),
                experiences=result_data.get("experiences", []),
                education=result_data.get("education", []),
                skills=result_data.get("skills", [])
            )
            db.add(profile)
        else:
            profile.full_name = result_data.get("full_name", profile.full_name)
            profile.title = result_data.get("title", profile.title)
            profile.email = result_data.get("email", profile.email)
            profile.phone = result_data.get("phone", profile.phone)
            profile.location = result_data.get("location", profile.location)
            profile.bio = result_data.get("bio", profile.bio)
            
            # Merge or overwrite experiences
            profile.experiences = result_data.get("experiences", [])
            profile.education = result_data.get("education", [])
            profile.skills = result_data.get("skills", [])
            
        await db.commit()
        await db.refresh(profile)
        
        return await ProfileService.get_full_profile(db, current_user)
