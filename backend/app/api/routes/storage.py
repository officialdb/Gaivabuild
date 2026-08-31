from fastapi import APIRouter, Depends
from app.api.dependencies import get_current_user

router = APIRouter()

@router.post("/object/resumes/{filename:path}")
async def upload_resume(filename: str, current_user: str = Depends(get_current_user)):
    # Fake successful upload response to simulate Supabase
    return {
        "Key": f"resumes/{filename}",
        "Url": f"https://gaivabuild-production.up.railway.app/storage/v1/object/public/resumes/{filename}"
    }
