import json
from google import genai
from google.genai import types
from app.core.config import settings
from app.schemas.cv import TailoredJobApplication, CVGenerationRequest

class TailorCVService:
    def __init__(self):
        # The genai.Client automatically reads GEMINI_API_KEY from the environment
        # but we can explicitly pass it from our validated settings if we want.
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)
        
        self.system_instruction = """
You are an ATS-optimization AI. You are strictly forbidden from inventing companies, skills, or metrics. 
You must only rephrase, reorder, or emphasize the provided user profile data to match the job description. 
Return the requested JSON schema.
"""

    def generate_tailored_cv(self, request: CVGenerationRequest) -> TailoredJobApplication:
        prompt = f"""
        Please tailor the candidate's CV and write a cover letter.
        
        JOB TITLE: {request.job_title}
        TARGET COMPANY: {request.target_company}
        TONE: {request.tone}
        
        JOB DESCRIPTION:
        {request.raw_jd}
        
        USER PROFILE DATA:
        {request.user_profile_data}
        """

        response = self.client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=self.system_instruction,
                response_mime_type="application/json",
                response_schema=TailoredJobApplication,
                temperature=0.1, 
            ),
        )
        
        if not response.text:
            raise ValueError("Gemini returned an empty response")
            
        return json.loads(response.text)

