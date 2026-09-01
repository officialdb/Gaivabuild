from sqlalchemy import Column, String, ForeignKey, DateTime, JSON
from app.core.database import Base
from datetime import datetime
import uuid

class MasterProfile(Base):
    __tablename__ = "master_profiles"
    
    id = Column(String, primary_key=True, default=lambda: f"prof_{uuid.uuid4().hex[:8]}")
    user_email = Column(String, ForeignKey("users.email"), nullable=False, unique=True)
    
    full_name = Column(String, nullable=False)
    title = Column(String, nullable=True)
    email = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    location = Column(String, nullable=True)
    bio = Column(String, nullable=True)
    
    linkedin_url = Column(String, nullable=True)
    github_url = Column(String, nullable=True)
    portfolio_url = Column(String, nullable=True)
    
    skills = Column(JSON, default=list)
    experiences = Column(JSON, default=list)
    education = Column(JSON, default=list)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
