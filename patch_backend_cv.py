import re
with open('backend/app/api/routes/legacy_cv.py', 'r') as f:
    content = f.read()

extraction = """
    name_match = re.search(r"Name:\s*(.*)", user_profile_data)
    candidate_name = name_match.group(1).strip() if name_match else "Candidate"
    
    bio_match = re.search(r"Bio:\s*(.*)", user_profile_data)
    bio = bio_match.group(1).strip() if bio_match else ""
    
    edu_match = re.search(r"Education:\s*(.*)", user_profile_data)
    education = edu_match.group(1).strip() if edu_match else ""
"""

target = """    name_match = re.search(r"Name:\s*(.*)", user_profile_data)
    candidate_name = name_match.group(1).strip() if name_match else "Candidate"
"""

content = content.replace(target, extraction)
content = content.replace('"tone": tone,', '"tone": tone,\n        "bio": bio,\n        "education": education,')

with open('backend/app/api/routes/legacy_cv.py', 'w') as f:
    f.write(content)
