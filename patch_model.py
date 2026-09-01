with open('lib/models/tailored_application.dart', 'r') as f:
    content = f.read()

# Add fields
content = content.replace("final String candidateName;", "final String candidateName;\n  final String bio;\n  final String education;")
content = content.replace("this.candidateName = 'Candidate',", "this.candidateName = 'Candidate',\n    this.bio = '',\n    this.education = '',")
content = content.replace("candidateName: json['candidate_name'] as String? ?? json['candidateName'] as String? ?? 'Candidate',", "candidateName: json['candidate_name'] as String? ?? json['candidateName'] as String? ?? 'Candidate',\n      bio: json['bio'] as String? ?? '',\n      education: json['education'] as String? ?? '',")
content = content.replace("'target_company': targetCompany,", "'target_company': targetCompany,\n      'bio': bio,\n      'education': education,")

with open('lib/models/tailored_application.dart', 'w') as f:
    f.write(content)
