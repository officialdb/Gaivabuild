import re

with open('lib/services/document_generator_service.dart', 'r') as f:
    content = f.read()

# Replace Bio string
content = content.replace(
    "'Lead Mobile Architect with 6+ years of specialized experience in high-concurrency cross-platform Flutter systems, PostgreSQL data modeling, and automated CI/CD deployment pipelines. Proven track record scaling applications to 1.2M+ active users with 99.9% crash-free reliability.',",
    "application.bio.isNotEmpty ? application.bio : 'Professional software engineer dedicated to building scalable systems.',"
)

# Replace Education string
content = content.replace(
    "'B.S. in Computer Science — University of Texas at Austin',",
    "application.education.isNotEmpty ? application.education : 'B.S. in Computer Science',"
)

# Replace Date string
content = content.replace(
    "'2016 - 2020',",
    "'',"
)

# Also replace for DOCX generator
content = content.replace(
    "Lead Mobile Architect with 6+ years of specialized experience in high-concurrency cross-platform Flutter systems, PostgreSQL data modeling, and automated CI/CD deployment pipelines. Proven track record scaling applications to 1.2M+ active users with 99.9% crash-free reliability.",
    "${application.bio.isNotEmpty ? application.bio : 'Professional software engineer dedicated to building scalable systems.'}"
)

content = content.replace(
    "B.S. in Computer Science — University of Texas at Austin (2016 - 2020)",
    "${application.education.isNotEmpty ? application.education : 'B.S. in Computer Science'}"
)

with open('lib/services/document_generator_service.dart', 'w') as f:
    f.write(content)
