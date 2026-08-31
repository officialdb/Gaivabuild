from fastapi import APIRouter, Depends, Response
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
