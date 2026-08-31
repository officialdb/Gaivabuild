from pydantic import BaseModel, Field
from typing import Optional

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8)

class TwoFactorToggleResponse(BaseModel):
    enabled: bool
    secret: Optional[str] = None
    qr_code_url: Optional[str] = None
