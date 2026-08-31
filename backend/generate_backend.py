import os

files = {
    "app/schemas/profile.py": '''from pydantic import BaseModel, HttpUrl, Field
from typing import List, Optional

class ProfileDetails(BaseModel):
    full_name: str
    job_title: Optional[str] = None
    phone: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None

class ProfileLinks(BaseModel):
    linkedin_url: Optional[HttpUrl] = None
    github_url: Optional[HttpUrl] = None
    portfolio_url: Optional[HttpUrl] = None

class Bullet(BaseModel):
    id: str
    text: str

class Experience(BaseModel):
    id: str
    company: str
    role: str
    start_date: str
    end_date: Optional[str] = None
    bullets: List[Bullet] = []

class Education(BaseModel):
    id: str
    institution: str
    degree: str
    start_date: str
    end_date: Optional[str] = None

class SkillsCategory(BaseModel):
    hard_skills: List[str] = []
    soft_skills: List[str] = []
    frameworks: List[str] = []

class FullProfile(BaseModel):
    details: ProfileDetails
    links: ProfileLinks
    experience: List[Experience] = []
    education: List[Education] = []
    skills: SkillsCategory
''',
    "app/schemas/account.py": '''from pydantic import BaseModel, Field
from typing import Optional

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8)

class TwoFactorToggleResponse(BaseModel):
    enabled: bool
    secret: Optional[str] = None
    qr_code_url: Optional[str] = None
''',
    "app/schemas/export.py": '''from pydantic import BaseModel
from app.schemas.cv import TailoredJobApplication

class DocumentExportRequest(BaseModel):
    cv: TailoredJobApplication
    cover_letter: dict = None
''',
    "app/services/profile_service.py": '''class ProfileService:
    @staticmethod
    async def get_full_profile(db, user_id: str):
        pass

    @staticmethod
    async def update_details(db, user_id: str, data):
        pass

    @staticmethod
    async def update_links(db, user_id: str, data):
        pass

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
    async def parse_cv(file_bytes: bytes) -> dict:
        return {}
''',
    "app/services/account_service.py": '''class AccountService:
    @staticmethod
    async def change_password(db, user_id: str, current_password: str, new_password: str):
        pass

    @staticmethod
    async def toggle_2fa(db, user_id: str):
        return {"enabled": True, "secret": "mock", "qr_code_url": "mock_url"}

    @staticmethod
    async def export_json(db, user_id: str):
        return {}

    @staticmethod
    async def clear_cache(db, user_id: str):
        pass

    @staticmethod
    async def logout(db, user_id: str, token: str):
        pass

    @staticmethod
    async def delete_account(db, user_id: str):
        pass
''',
    "app/services/tailor_service.py": '''import asyncio
import json
from app.schemas.cv import TailoredJobApplication

class TailorService:
    @staticmethod
    async def stream_tailoring(request_data):
        yield f"data: {json.dumps({'step': 1, 'progress': 29, 'status': 'Analyzing Job Requirements'})}\\n\\n"
        await asyncio.sleep(1)
        yield f"data: {json.dumps({'step': 2, 'progress': 65, 'status': 'Querying Master Profile RAG Engine'})}\\n\\n"
        await asyncio.sleep(1)
        # Mock final response
        yield f"data: {json.dumps({'step': 3, 'progress': 100, 'status': 'Completed', 'result': {}})}\\n\\n"
''',
    "app/services/export_service.py": '''class ExportService:
    @staticmethod
    async def generate_pdf(data):
        return b"mock pdf data"

    @staticmethod
    async def generate_docx(data):
        return b"mock docx data"
''',
    "app/api/routes/profile.py": '''from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from app.api.dependencies import get_current_user, get_db
from app.schemas.profile import FullProfile, ProfileDetails, ProfileLinks, Experience, Education, SkillsCategory
from app.services.profile_service import ProfileService

router = APIRouter()

@router.get("/", response_model=FullProfile)
async def get_profile(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await ProfileService.get_full_profile(db, current_user)

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
async def update_skills(data: SkillsCategory, current_user: str = Depends(get_current_user), db = Depends(get_db)):
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
''',
    "app/api/routes/account.py": '''from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from app.api.dependencies import get_current_user, get_db, oauth2_scheme
from app.schemas.account import ChangePasswordRequest, TwoFactorToggleResponse
from app.services.account_service import AccountService

router = APIRouter()

@router.post("/change-password")
async def change_password(data: ChangePasswordRequest, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    await AccountService.change_password(db, current_user, data.current_password, data.new_password)
    return {"msg": "Password updated"}

@router.post("/2fa/toggle", response_model=TwoFactorToggleResponse)
async def toggle_2fa(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return await AccountService.toggle_2fa(db, current_user)

@router.get("/export-json")
async def export_json(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    data = await AccountService.export_json(db, current_user)
    return JSONResponse(content=data, headers={"Content-Disposition": 'attachment; filename="master_profile.json"'})

@router.delete("/clear-cache")
async def clear_cache(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    await AccountService.clear_cache(db, current_user)
    return {"msg": "Cache cleared"}

@router.post("/logout")
async def logout(token: str = Depends(oauth2_scheme), current_user: str = Depends(get_current_user), db = Depends(get_db)):
    await AccountService.logout(db, current_user, token)
    return {"msg": "Logged out"}

@router.delete("/delete", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(current_user: str = Depends(get_current_user), db = Depends(get_db)):
    await AccountService.delete_account(db, current_user)
''',
    "app/api/routes/cv_generator.py": '''from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from app.api.dependencies import get_current_user, get_db
from app.schemas.cv import CVGenerationRequest
from app.services.tailor_service import TailorService

router = APIRouter()

@router.post("/tailor/stream")
async def tailor_stream(request: CVGenerationRequest, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return StreamingResponse(TailorService.stream_tailoring(request), media_type="text/event-stream")
''',
    "app/api/routes/export.py": '''from fastapi import APIRouter, Depends, Response
from app.api.dependencies import get_current_user, get_db
from app.schemas.export import DocumentExportRequest
from app.services.export_service import ExportService

router = APIRouter()

@router.post("/pdf")
async def export_pdf(request: DocumentExportRequest, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    pdf_bytes = await ExportService.generate_pdf(request)
    return Response(content=pdf_bytes, media_type="application/pdf")

@router.post("/docx")
async def export_docx(request: DocumentExportRequest, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    docx_bytes = await ExportService.generate_docx(request)
    return Response(content=docx_bytes, media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document")
'''
}

for filepath, content in files.items():
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "w") as f:
        f.write(content)

print("Backend files generated!")
