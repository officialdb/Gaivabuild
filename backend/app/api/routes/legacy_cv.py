from fastapi import APIRouter, Body
from typing import Any, Dict
import random
import uuid

router = APIRouter()

@router.post("/generate-cv")
async def generate_cv(payload: Dict[Any, Any] = Body(...)):
    # Mock realistic response conforming to TailoredJobApplication
    job_title = payload.get("job_title", "Senior Software Engineer")
    target_company = payload.get("target_company", "Tech Corp")
    
    return {
        "id": f"app_{uuid.uuid4()}",
        "candidate_name": "Candidate",
        "job_title": job_title,
        "target_company": target_company,
        "tone": payload.get("tone", "Professional"),
        "ats_match_score": random.randint(85, 98),
        "matched_keywords": ["Python", "FastAPI", "Flutter", "PostgreSQL", "Cloud"],
        "missing_keywords": ["GraphQL", "Kafka"],
        "sections": [
            {
                "company": "Previous Tech",
                "role": "Software Engineer",
                "date_range": "2020 - Present",
                "bullets": [
                    {
                        "id": f"tb_{uuid.uuid4()}",
                        "original_text": "Built web applications.",
                        "tailored_text": f"Engineered scalable web architectures using modern frameworks to align with {target_company}'s high-throughput requirements.",
                        "is_modified": True,
                        "is_approved": False
                    },
                    {
                        "id": f"tb_{uuid.uuid4()}",
                        "original_text": "Fixed bugs and wrote tests.",
                        "tailored_text": "Spearheaded comprehensive test-driven development, resulting in a 40% decrease in production bugs and enhancing overall system reliability.",
                        "is_modified": True,
                        "is_approved": False
                    }
                ]
            }
        ],
        "created_at": "2026-08-31T20:00:00Z"
    }
