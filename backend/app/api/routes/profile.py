from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.api.dependencies import get_current_user, get_db
from typing import List, Any
from app.schemas.profile import FullProfile, ProfileDetails, ProfileLinks, Experience, Education, SkillItem
from app.services.profile_service import ProfileService

router = APIRouter()

@router.get("", response_model=List[Any])
async def get_profile(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    profile = await ProfileService.get_full_profile(db, current_user)
    return [profile]

@router.post("", response_model=List[Any])
async def upsert_profile(data: List[Any], current_user: str = Depends(get_current_user), db = Depends(get_db)):
    # Legacy Supabase upsert simulation
    return data

@router.put("/details")
async def update_details(data: ProfileDetails, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.update_details(db, current_user, data)

@router.put("/links")
async def update_links(data: ProfileLinks, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.update_links(db, current_user, data)

@router.post("/experience")
async def create_experience(data: Experience, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.create_experience(db, current_user, data)

@router.put("/experience/{id}")
async def update_experience(id: str, data: Experience, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.update_experience(db, current_user, id, data)

@router.delete("/experience/{id}")
async def delete_experience(id: str, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.delete_experience(db, current_user, id)

@router.put("/skills")
async def update_skills(data: List[SkillItem], current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.update_skills(db, current_user, data)

@router.post("/education")
async def create_education(data: Education, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.create_education(db, current_user, data)

@router.put("/education/{id}")
async def update_education(id: str, data: Education, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.update_education(db, current_user, id, data)

@router.delete("/education/{id}")
async def delete_education(id: str, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.delete_education(db, current_user, id)

@router.post("/parse-cv")
async def parse_cv(file: UploadFile = File(...), current_user: str = Depends(get_current_user), db = Depends(get_db)):
    content = await file.read()
    return await ProfileService.parse_cv(content)
