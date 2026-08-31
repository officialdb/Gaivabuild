from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from app.api.dependencies import get_current_user, get_db
from app.schemas.cv import CVGenerationRequest
from app.services.tailor_service import TailorService

router = APIRouter()

@router.post("/tailor/stream")
async def tailor_stream(request: CVGenerationRequest, current_user: str = Depends(get_current_user), db = Depends(get_db)):
    return StreamingResponse(TailorService.stream_tailoring(request), media_type="text/event-stream")
