with open('lib/screens/final_pdf_preview_screen.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "'Lead Mobile Architect with 6+ years of specialized experience in high-concurrency cross-platform Flutter systems, PostgreSQL data modeling, and automated CI/CD deployment pipelines. Proven track record scaling applications to 1.2M+ active users with 99.9% crash-free reliability.',",
    "widget.application.bio.isNotEmpty ? widget.application.bio : 'Professional software engineer dedicated to building scalable systems.',"
)

content = content.replace(
    "'B.S. in Computer Science — University of Texas at Austin',",
    "widget.application.education.isNotEmpty ? widget.application.education : 'B.S. in Computer Science',"
)

content = content.replace(
    "'2016 - 2020',",
    "'',"
)

with open('lib/screens/final_pdf_preview_screen.dart', 'w') as f:
    f.write(content)
