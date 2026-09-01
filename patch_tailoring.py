with open('lib/services/ai_tailoring_service.dart', 'r') as f:
    content = f.read()

new_payload = """    final userProfileData = '''
Name: ${masterProfile.fullName}
Title: ${masterProfile.title}
Bio: ${masterProfile.bio.isNotEmpty ? masterProfile.bio : 'Candidate Bio'}
Education: ${masterProfile.education.isNotEmpty ? masterProfile.education.map((e) => "${e.degree} at ${e.institution} (${e.startYear}-${e.endYear})").join(" | ") : 'B.S. Computer Science'}
Skills: ${masterProfile.skills.map((s) => s.name).join(", ")}
Work Experiences:
${masterProfile.experiences.map((exp) => "Role: ${exp.title} at ${exp.company} (${exp.startDate} - ${exp.endDate})\\nBullets:\\n${exp.bullets.map((b) => "- ${b.text}").join("\\n")}").join("\\n\\n")}
''';"""

import re
content = re.sub(r"    final userProfileData = '''[\s\S]*?''';", new_payload, content)

with open('lib/services/ai_tailoring_service.dart', 'w') as f:
    f.write(content)
