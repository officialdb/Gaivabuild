from pydantic import BaseModel
from app.schemas.cv import TailoredJobApplication

class DocumentExportRequest(BaseModel):
    cv: TailoredJobApplication
    cover_letter: dict = None
