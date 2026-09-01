from pydantic import BaseModel, EmailStr
from typing import Optional, Union

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    full_name: Optional[str] = None

class User(UserBase):
    id: Optional[Union[int, str]] = 1
    full_name: Optional[str] = None
    
    class Config:
        from_attributes = True

