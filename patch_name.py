import re

with open('backend/app/api/routes/legacy_cv.py', 'r') as f:
    content = f.read()

name_extraction = """
    name_match = re.search(r"Name:\s*(.*)", user_profile_data)
    candidate_name = name_match.group(1).strip() if name_match else "Candidate"
"""

content = content.replace('    prompt = f"""', name_extraction + '\n    prompt = f"""')
content = content.replace('"candidate_name": "Candidate",', '"candidate_name": candidate_name,')

with open('backend/app/api/routes/legacy_cv.py', 'w') as f:
    f.write(content)
