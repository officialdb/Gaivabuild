from pydantic import BaseModel, HttpUrl, Field
from typing import List, Optional
from enum import Enum

class ProfileDetails(BaseModel):
    full_name: str
    title: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None

class ProfileLinks(BaseModel):
    linkedin_url: Optional[str] = None
    github_url: Optional[str] = None
    portfolio_url: Optional[str] = None

class Bullet(BaseModel):
    id: str
    text: str

class Experience(BaseModel):
    id: str
    company: str
    title: str
    location: str
    start_date: str
    end_date: Optional[str] = None
    is_current: bool = False
    bullets: List[Bullet] = []

class Education(BaseModel):
    id: str
    institution: str
    degree: str
    field_of_study: str
    start_year: str
    end_year: Optional[str] = None
    grade_or_honors: Optional[str] = None

class SkillCategoryEnum(str, Enum):
    hard = "hard"
    soft = "soft"
    tool = "tool"

class SkillItem(BaseModel):
    id: str
    name: str
    category: Optional[str] = "hard"

class FullProfile(BaseModel):
    id: str
    full_name: str
    title: str
    email: str
    phone: str
    location: str
    bio: str
    linkedin_url: Optional[str] = None
    github_url: Optional[str] = None
    portfolio_url: Optional[str] = None
    experiences: List[Experience] = []
    education: List[Education] = []
    skills: List[SkillItem] = []
