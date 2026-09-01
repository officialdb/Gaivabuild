class MasterProfile {
  final String id;
  final String fullName;
  final String title;
  final String email;
  final String phone;
  final String location;
  final String bio;
  final String? linkedInUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final List<WorkExperience> experiences;
  final List<EducationEntry> education;
  final List<SkillItem> skills;

  MasterProfile({
    required this.id,
    required this.fullName,
    required this.title,
    required this.email,
    required this.phone,
    required this.location,
    required this.bio,
    this.linkedInUrl,
    this.githubUrl,
    this.portfolioUrl,
    required this.experiences,
    required this.education,
    required this.skills,
  });

  static MasterProfile empty({String? name, String? email}) {
    return MasterProfile(
      id: 'prof_${DateTime.now().millisecondsSinceEpoch}',
      fullName: (name != null && name.trim().isNotEmpty) ? name.trim() : 'Candidate',
      title: 'Professional Profile',
      email: (email != null && email.trim().isNotEmpty) ? email.trim() : '',
      phone: '',
      location: '',
      bio: '',
      linkedInUrl: null,
      githubUrl: null,
      portfolioUrl: null,
      experiences: [],
      education: [],
      skills: [],
    );
  }

  MasterProfile copyWith({
    String? id,
    String? fullName,
    String? title,
    String? email,
    String? phone,
    String? location,
    String? bio,
    String? linkedInUrl,
    String? githubUrl,
    String? portfolioUrl,
    List<WorkExperience>? experiences,
    List<EducationEntry>? education,
    List<SkillItem>? skills,
  }) {
    return MasterProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      title: title ?? this.title,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      skills: skills ?? this.skills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'title': title,
      'email': email,
      'phone': phone,
      'location': location,
      'bio': bio,
      'linkedin_url': linkedInUrl,
      'github_url': githubUrl,
      'portfolio_url': portfolioUrl,
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'education': education.map((ed) => ed.toJson()).toList(),
      'skills': skills.map((s) => s.toJson()).toList(),
    };
  }

  factory MasterProfile.fromJson(Map<String, dynamic> json) {
    return MasterProfile(
      id: json['id'] as String? ?? 'prof_${DateTime.now().millisecondsSinceEpoch}',
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? 'Candidate',
      title: json['title'] as String? ?? 'Software Engineer',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      linkedInUrl: json['linkedin_url'] as String? ?? json['linkedInUrl'] as String?,
      githubUrl: json['github_url'] as String? ?? json['githubUrl'] as String?,
      portfolioUrl: json['portfolio_url'] as String? ?? json['portfolioUrl'] as String?,
      experiences: (json['experiences'] as List?)
              ?.map((e) => WorkExperience.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      education: (json['education'] as List?)
              ?.map((ed) => EducationEntry.fromJson(Map<String, dynamic>.from(ed as Map)))
              .toList() ??
          [],
      skills: (json['skills'] as List?)?.map((s) {
            if (s is String) {
              return SkillItem(
                  id: 'sk_${s.hashCode}', name: s, category: SkillCategory.hard);
            }
            return SkillItem.fromJson(Map<String, dynamic>.from(s as Map));
          }).toList() ??
          [],
    );
  }
}

class WorkExperience {
  final String id;
  final String company;
  final String title;
  final String location;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final List<ExperienceBullet> bullets;

  WorkExperience({
    required this.id,
    required this.company,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.bullets,
  });

  WorkExperience copyWith({
    String? id,
    String? company,
    String? title,
    String? location,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    List<ExperienceBullet>? bullets,
  }) {
    return WorkExperience(
      id: id ?? this.id,
      company: company ?? this.company,
      title: title ?? this.title,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      bullets: bullets ?? this.bullets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': company,
      'title': title,
      'location': location,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      'bullets': bullets.map((b) => b.toJson()).toList(),
    };
  }

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: json['id'] as String? ?? 'exp_${DateTime.now().millisecondsSinceEpoch}',
      company: json['company'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      startDate: json['start_date'] as String? ?? json['startDate'] as String? ?? '',
      endDate: json['end_date'] as String? ?? json['endDate'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? json['isCurrent'] as bool? ?? false,
      bullets: (json['bullets'] as List?)?.map((b) {
            if (b is String) {
              return ExperienceBullet(id: 'b_${b.hashCode}', text: b);
            }
            return ExperienceBullet.fromJson(Map<String, dynamic>.from(b as Map));
          }).toList() ??
          [],
    );
  }
}

class ExperienceBullet {
  final String id;
  final String text;

  ExperienceBullet({
    required this.id,
    required this.text,
  });

  ExperienceBullet copyWith({
    String? id,
    String? text,
  }) {
    return ExperienceBullet(
      id: id ?? this.id,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory ExperienceBullet.fromJson(Map<String, dynamic> json) {
    return ExperienceBullet(
      id: json['id'] as String? ?? 'b_${DateTime.now().millisecondsSinceEpoch}',
      text: json['text'] as String? ?? '',
    );
  }
}

class EducationEntry {
  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String startYear;
  final String endYear;
  final String? gradeOrHonors;

  EducationEntry({
    required this.id,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startYear,
    required this.endYear,
    this.gradeOrHonors,
  });

  EducationEntry copyWith({
    String? id,
    String? institution,
    String? degree,
    String? fieldOfStudy,
    String? startYear,
    String? endYear,
    String? gradeOrHonors,
  }) {
    return EducationEntry(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      gradeOrHonors: gradeOrHonors ?? this.gradeOrHonors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institution': institution,
      'degree': degree,
      'field_of_study': fieldOfStudy,
      'start_year': startYear,
      'end_year': endYear,
      'grade_or_honors': gradeOrHonors,
    };
  }

  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    return EducationEntry(
      id: json['id'] as String? ?? 'edu_${DateTime.now().millisecondsSinceEpoch}',
      institution: json['institution'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      fieldOfStudy: json['field_of_study'] as String? ?? json['fieldOfStudy'] as String? ?? '',
      startYear: json['start_year']?.toString() ?? json['startYear']?.toString() ?? '',
      endYear: json['end_year']?.toString() ?? json['endYear']?.toString() ?? '',
      gradeOrHonors: json['grade_or_honors'] as String? ?? json['gradeOrHonors'] as String?,
    );
  }
}

enum SkillCategory { hard, soft, tool }

class SkillItem {
  final String id;
  final String name;
  final SkillCategory category;

  SkillItem({
    required this.id,
    required this.name,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
    };
  }

  factory SkillItem.fromJson(Map<String, dynamic> json) {
    return SkillItem(
      id: json['id'] as String? ?? 'sk_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '',
      category: json['category'] == 'soft'
          ? SkillCategory.soft
          : json['category'] == 'tool'
              ? SkillCategory.tool
              : SkillCategory.hard,
    );
  }
}
