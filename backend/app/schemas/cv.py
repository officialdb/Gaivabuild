from pydantic import BaseModel, Field
from typing import List, Dict, Any

class TailoredBullet(BaseModel):
    id: str = Field(description="Unique ID for the bullet, e.g., 'tb_1'")
    original_text: str = Field(description="The original text from the master profile")
    tailored_text: str = Field(description="The optimized text matching the JD keywords")
    is_modified: bool = Field(default=True, description="True if the text was changed")
    is_approved: bool = Field(default=True, description="True if approved")

class TailoredSection(BaseModel):
    company: str = Field(description="Company name")
    role: str = Field(description="Role title")
    date_range: str = Field(description="Date range")
    bullets: List[TailoredBullet] = Field(description="The bullet points for this role")

class TailoredJobApplication(BaseModel):
    job_title: str = Field(description="Target role title")
    target_company: str = Field(description="Target company name")
    ats_match_score: int = Field(description="An objective ATS match score between 0 and 100")
    matched_keywords: List[str] = Field(description="Keywords from the JD found in the profile")
    missing_keywords: List[str] = Field(description="Keywords required by the JD but missing from the profile")
    sections: List[TailoredSection] = Field(description="Tailored work experience sections")

class CVGenerationRequest(BaseModel):
    job_title: str
    target_company: str
    tone: str
    raw_jd: str
    user_profile_data: str

