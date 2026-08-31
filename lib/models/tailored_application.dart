class TailoredJobApplication {
  final String id;
  final String candidateName;
  final String jobTitle;
  final String targetCompany;
  final String rawJobDescription;
  final String tone;
  final int atsMatchScore;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<TailoredSection> sections;
  final DateTime createdAt;

  TailoredJobApplication({
    required this.id,
    this.candidateName = 'Candidate',
    required this.jobTitle,
    required this.targetCompany,
    required this.rawJobDescription,
    required this.tone,
    required this.atsMatchScore,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.sections,
    required this.createdAt,
  });

  factory TailoredJobApplication.fromJson(Map<String, dynamic> json) {
    return TailoredJobApplication(
      id: json['id'] as String? ?? 'app_${DateTime.now().millisecondsSinceEpoch}',
      candidateName: json['candidate_name'] as String? ?? json['candidateName'] as String? ?? 'Candidate',
      jobTitle: json['job_title'] as String? ?? json['jobTitle'] as String? ?? 'Target Role',
      targetCompany: json['target_company'] as String? ?? json['targetCompany'] as String? ?? 'Target Company',
      rawJobDescription: json['raw_jd'] as String? ?? json['rawJobDescription'] as String? ?? '',
      tone: json['tone'] as String? ?? 'Professional',
      atsMatchScore: (json['ats_match_score'] ?? json['atsMatchScore']) as int? ?? (throw Exception("Missing ATS Match Score in AI response")),
      matchedKeywords: (json['matched_keywords'] as List? ?? json['matchedKeywords'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      missingKeywords: (json['missing_keywords'] as List? ?? json['missingKeywords'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      sections: (json['sections'] as List? ?? [])
          .map((e) => TailoredSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_title': jobTitle,
      'target_company': targetCompany,
      'raw_jd': rawJobDescription,
      'tone': tone,
      'ats_match_score': atsMatchScore,
      'matched_keywords': matchedKeywords,
      'missing_keywords': missingKeywords,
      'sections': sections.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TailoredSection {
  final String company;
  final String role;
  final String dateRange;
  final List<TailoredBullet> bullets;

  TailoredSection({
    required this.company,
    required this.role,
    required this.dateRange,
    required this.bullets,
  });

  factory TailoredSection.fromJson(Map<String, dynamic> json) {
    return TailoredSection(
      company: json['company'] as String? ?? 'Company',
      role: json['role'] as String? ?? 'Role',
      dateRange: json['date_range'] as String? ?? json['dateRange'] as String? ?? '',
      bullets: (json['bullets'] as List? ?? [])
          .map((e) => TailoredBullet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'role': role,
      'date_range': dateRange,
      'bullets': bullets.map((b) => b.toJson()).toList(),
    };
  }
}

class TailoredBullet {
  final String id;
  final String originalText;
  String tailoredText;
  final bool isModified;
  bool isApproved;

  TailoredBullet({
    required this.id,
    required this.originalText,
    required this.tailoredText,
    required this.isModified,
    this.isApproved = false,
  });

  factory TailoredBullet.fromJson(Map<String, dynamic> json) {
    return TailoredBullet(
      id: json['id'] as String? ?? 'tb_${DateTime.now().millisecondsSinceEpoch}',
      originalText: json['original_text'] as String? ?? json['originalText'] as String? ?? '',
      tailoredText: json['tailored_text'] as String? ?? json['tailoredText'] as String? ?? '',
      isModified: json['is_modified'] as bool? ?? json['isModified'] as bool? ?? true,
      isApproved: json['is_approved'] as bool? ?? json['isApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'original_text': originalText,
      'tailored_text': tailoredText,
      'is_modified': isModified,
      'is_approved': isApproved,
    };
  }
}
