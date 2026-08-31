import 'dart:convert';
import 'package:archive/archive.dart';
import '../models/master_profile.dart';

class ResumeParserService {
  /// Known technical skills taxonomy for dynamic document text matching
  static const Set<String> _knownTechnicalSkills = {
    'Flutter', 'Dart', 'Java', 'Kotlin', 'Swift', 'Objective-C', 'Python', 'C++',
    'C#', 'Go', 'Rust', 'JavaScript', 'TypeScript', 'React', 'React Native',
    'Vue.js', 'Angular', 'Node.js', 'Express', 'Django', 'Flask', 'Spring Boot',
    'Laravel', 'Next.js', 'Nuxt', 'FastAPI', 'PHP', 'Ruby', 'Rails',
    'SQL', 'PostgreSQL', 'MySQL', 'MongoDB', 'Redis', 'GraphQL', 'REST APIs',
    'Firebase', 'AWS', 'GCP', 'Azure', 'Docker', 'Kubernetes', 'Terraform', 'HTML', 'CSS',
  };

  static const Set<String> _knownToolSkills = {
    'Git', 'GitHub', 'GitLab', 'CI/CD', 'Jenkins', 'Docker', 'Postman',
    'Figma', 'Jira', 'Confluence', 'VS Code', 'Android Studio', 'Xcode', 'Fastlane',
    'Paystack', 'WhatsApp Cloud API', 'FCM', 'Riverpod', 'BLoC',
  };

  static const Set<String> _knownSoftSkills = {
    'Leadership', 'Team Leadership', 'Project Management', 'Agile', 'Scrum',
    'Communication', 'Problem Solving', 'Strategic Thinking', 'Mentorship',
  };

  /// Main entry point to parse PDF, DOCX, or text resume file into MasterProfile
  static MasterProfile parseResumeDocument({
    required String fileName,
    required List<int> bytes,
    String? userEmail,
    String? userName,
  }) {
    // 1. Extract clean text (stripping ZIP / XML / PDF binary data)
    final cleanText = _extractTextFromFile(fileName, bytes);

    final lines = cleanText
        .split(RegExp(r'\r?\n'))
        .map((l) => _cleanXmlTags(l))
        .where((l) => l.isNotEmpty && !_isRawXmlOrBinary(l))
        .toList();

    // 2. Extract Social & Portfolio Links
    final linkedInUrl = _extractLinkedIn(cleanText);
    final githubUrl = _extractGitHub(cleanText);
    final portfolioUrl = _extractPortfolioUrl(cleanText);

    // 3. Extract Contact Details & Candidate Identity
    final email = _extractEmail(cleanText) ?? (userEmail != null && userEmail.isNotEmpty ? userEmail : '');
    final phone = _extractPhone(cleanText) ?? '';
    final location = _extractLocation(lines) ?? '';
    final candidateName = _extractCandidateName(lines, userName);
    final candidateTitle = _extractCandidateTitle(lines);

    // 4. Extract Education & Certifications
    final education = _extractEducation(lines);

    // 5. Extract Work Experience (strictly excluding candidate name, education, certifications, and boilerplate text)
    final experiences = _extractExperiences(lines, candidateName, userName);

    // 6. Extract Skills
    final skills = _extractSkills(cleanText);

    return MasterProfile(
      id: 'prof_${DateTime.now().millisecondsSinceEpoch}',
      fullName: candidateName,
      title: candidateTitle,
      email: email,
      phone: phone,
      location: location,
      bio: 'Extracted profile from $fileName',
      linkedInUrl: linkedInUrl,
      githubUrl: githubUrl,
      portfolioUrl: portfolioUrl,
      experiences: experiences,
      skills: skills,
      education: education,
    );
  }

  /// Extracts clean text from DOCX (ZIP XML), PDF, or plain text
  static String _extractTextFromFile(String fileName, List<int> bytes) {
    final lowerName = fileName.toLowerCase();

    // DOCX ZIP Archive format
    if (lowerName.endsWith('.docx') || (bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B)) {
      final docxText = _extractTextFromDocx(bytes);
      if (docxText.trim().length > 10) return docxText;
    }

    // PDF Binary format
    if (lowerName.endsWith('.pdf') || (bytes.length > 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46)) {
      final pdfText = _extractTextFromPdf(bytes);
      if (pdfText.trim().length > 10) return pdfText;
    }

    // Fallback: UTF-8 string text
    try {
      final raw = utf8.decode(bytes, allowMalformed: true);
      return _cleanGarbageText(raw);
    } catch (_) {
      return _cleanGarbageText(String.fromCharCodes(bytes));
    }
  }

  /// Extracts text from DOCX `word/document.xml`
  static String _extractTextFromDocx(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final documentFile = archive.findFile('word/document.xml');
      if (documentFile == null) return '';

      final content = documentFile.content as List<int>;
      final xmlStr = utf8.decode(content, allowMalformed: true);

      final matches = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true).allMatches(xmlStr);
      final sb = StringBuffer();

      for (final m in matches) {
        final text = m.group(1);
        if (text != null && text.trim().isNotEmpty) {
          final clean = _cleanXmlTags(text);
          if (clean.isNotEmpty && !_isRawXmlOrBinary(clean)) {
            sb.writeln(clean);
          }
        }
      }

      return sb.toString();
    } catch (_) {
      return '';
    }
  }

  /// Extracts text from PDF streams
  static String _extractTextFromPdf(List<int> bytes) {
    try {
      final raw = String.fromCharCodes(bytes);
      final matches = RegExp(r'\((.*?)\)\s*(?:Tj|TJ)').allMatches(raw);
      final sb = StringBuffer();

      for (final m in matches) {
        final t = m.group(1);
        if (t != null && t.trim().isNotEmpty) {
          final cleaned = t
              .replaceAll(r'\(', '(')
              .replaceAll(r'\)', ')')
              .replaceAll(r'\\', r'\');
          final sanitised = _cleanXmlTags(cleaned);
          if (sanitised.isNotEmpty && !_isRawXmlOrBinary(sanitised)) {
            sb.writeln(sanitised);
          }
        }
      }

      final result = sb.toString();
      if (result.trim().length > 15) return result;

      return _cleanGarbageText(raw);
    } catch (_) {
      return '';
    }
  }

  static String _cleanGarbageText(String input) {
    final cleanAscii = _cleanXmlTags(input);
    final lines = cleanAscii
        .split(RegExp(r'\r?\n'))
        .map((l) => _cleanXmlTags(l))
        .where((l) => l.length > 2 && !_isRawXmlOrBinary(l))
        .join('\n');
    return lines;
  }

  /// Comprehensive XML Tag and Attribute Sanitizer
  static String _cleanXmlTags(String input) {
    if (input.isEmpty) return '';

    String text = input.replaceAll(RegExp(r'<[^>]*>'), ' ');

    text = text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");

    text = text.replaceAll(RegExp(r'w:[a-zA-Z0-9]+="[^"]*"'), ' ');
    text = text.replaceAll(RegExp(r'xml:[a-zA-Z0-9]+="[^"]*"'), ' ');
    text = text.replaceAll(RegExp(r'w:[a-zA-Z0-9]+'), ' ');

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  static bool _isRawXmlOrBinary(String line) {
    final lower = line.toLowerCase();
    if (lower.startsWith('pk') ||
        lower.contains('word/') ||
        lower.contains('xmlns:') ||
        lower.contains('w:val') ||
        lower.contains('w:pos') ||
        lower.contains('w:rpr') ||
        lower.contains('w:ppr') ||
        lower.contains('w:tbl') ||
        lower.contains('w:spacing') ||
        lower.contains('w:tab') ||
        lower.contains('rsidr') ||
        lower.contains('xml:space')) {
      return true;
    }
    if (line.contains('<<') || line.contains('>>') || line.startsWith('endobj') || line.startsWith('stream')) {
      return true;
    }
    final letters = line.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    if (line.length > 10 && letters.length / line.length < 0.35) {
      return true;
    }
    return false;
  }

  // --- LINK & BOILERPLATE EXTRACTION HELPER METHODS ---

  static String? _extractLinkedIn(String text) {
    final match = RegExp(r'(?:https?://)?(?:www\.)?linkedin\.com/in/([a-zA-Z0-9_-]+)', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final handle = match.group(1) ?? match.group(0)!;
      return 'linkedin.com/in/$handle';
    }
    return null;
  }

  static String? _extractGitHub(String text) {
    final match = RegExp(r'(?:https?://)?(?:www\.)?github\.com/([a-zA-Z0-9_-]+)', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final handle = match.group(1) ?? match.group(0)!;
      if (handle.toLowerCase() != 'in' && handle.toLowerCase() != 'orgs') {
        return 'github.com/$handle';
      }
    }
    return null;
  }

  static String? _extractPortfolioUrl(String text) {
    final matches = RegExp(r'https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/\S*)?', caseSensitive: false).allMatches(text);
    for (final m in matches) {
      final url = m.group(0)!;
      if (!url.contains('linkedin.com') && !url.contains('github.com')) {
        return url;
      }
    }
    return null;
  }

  static bool _isLinkLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('linkedin.com') ||
        lower.contains('github.com') ||
        lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.');
  }

  static bool _isEducationOrCertificationLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('bachelor') ||
        lower.contains('master') ||
        lower.contains('degree') ||
        lower.contains('b.s.') ||
        lower.contains('b.a.') ||
        lower.contains('b.sc') ||
        lower.contains('m.sc') ||
        lower.contains('university') ||
        lower.contains('polytechnic') ||
        lower.contains('college') ||
        lower.contains('diploma') ||
        lower.contains('hnd') ||
        lower.contains('n.d.') ||
        lower.contains('cisco') ||
        lower.contains('academy') ||
        lower.contains('certification') ||
        lower.contains('certificate') ||
        lower.contains('cybersecurity') ||
        lower.contains('essentials') ||
        lower.contains('coursera') ||
        lower.contains('udemy') ||
        lower.contains('edx') ||
        lower.contains('aws certified') ||
        lower.contains('meta certificate');
  }

  static bool _isBoilerplateOrCandidateName(String text, String candidateName, String? userName) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return true;

    final nameLower = candidateName.toLowerCase().trim();
    if (nameLower.isNotEmpty && (lower == nameLower || lower.contains(nameLower))) {
      return true;
    }

    if (userName != null && userName.trim().isNotEmpty) {
      final uLower = userName.toLowerCase().trim();
      if (lower == uLower || lower.contains(uLower)) return true;
    }

    if (lower.contains('references available') ||
        lower.contains('references upon request') ||
        lower.contains('curriculum vitae') ||
        lower.contains('resume') ||
        lower == 'education' ||
        lower == 'work experience' ||
        lower == 'skills' ||
        lower == 'certifications') {
      return true;
    }

    return false;
  }

  static String? _extractEmail(String text) {
    final match = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').firstMatch(text);
    return match?.group(0);
  }

  static String? _extractPhone(String text) {
    final match = RegExp(r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}').firstMatch(text);
    return match?.group(0);
  }

  static String? _extractLocation(List<String> lines) {
    final locationRegex = RegExp(r'([A-Z][a-zA-Z\s]+,\s*(?:[A-Z]{2}|[A-Z][a-zA-Z\s]+))');
    for (final line in lines.take(12)) {
      if (line.contains(',') && !line.contains('@') && !_isLinkLine(line) && !_isRawXmlOrBinary(line)) {
        final isSkillList = _knownTechnicalSkills.any((s) => line.toLowerCase().contains(s.toLowerCase()));
        if (!isSkillList) {
          final match = locationRegex.firstMatch(line);
          if (match != null) {
            return match.group(0);
          }
        }
      }
    }
    return null;
  }

  static String _extractCandidateName(List<String> lines, String? defaultName) {
    for (final line in lines.take(5)) {
      final clean = _cleanXmlTags(line);
      if (!clean.contains('@') && !_isLinkLine(clean) && !_isRawXmlOrBinary(clean) && clean.length > 2 && clean.length < 45) {
        final lower = clean.toLowerCase();
        if (!lower.contains('resume') && !lower.contains('curriculum') && !lower.contains('profile')) {
          final formatted = clean.replaceAll(RegExp(r'[^\w\s]'), '').trim();
          if (formatted.isNotEmpty && formatted.contains(' ')) {
            return formatted;
          }
        }
      }
    }
    if (defaultName != null && defaultName.trim().isNotEmpty && defaultName != 'Candidate') {
      return defaultName.trim();
    }
    return 'Candidate';
  }

  static String _extractCandidateTitle(List<String> lines) {
    final titleKeywords = [
      'engineer', 'developer', 'architect', 'manager', 'lead',
      'designer', 'analyst', 'consultant', 'specialist', 'administrator'
    ];
    for (final line in lines.take(8)) {
      final clean = _cleanXmlTags(line);
      final lower = clean.toLowerCase();
      if (titleKeywords.any((k) => lower.contains(k)) && clean.length < 50 && !_isLinkLine(clean) && !_isRawXmlOrBinary(clean)) {
        return clean;
      }
    }
    return 'Software Engineer';
  }

  static List<WorkExperience> _extractExperiences(List<String> lines, String candidateName, String? userName) {
    final results = <WorkExperience>[];
    final dateRegex = RegExp(r'((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|\d{4})\s*[-–\s]\s*(?:Present|\d{4}|Present|Current))', caseSensitive: false);

    String currentCompany = '';
    String currentTitle = '';
    String currentStartDate = '';
    String currentEndDate = '';
    bool currentIsCurrent = false;
    final currentBullets = <ExperienceBullet>[];
    bool inEducationSection = false;

    void commitCurrentExp() {
      if (currentBullets.isNotEmpty || currentTitle.isNotEmpty) {
        var cleanComp = _cleanXmlTags(currentCompany);
        var cleanTitl = _cleanXmlTags(currentTitle);

        if (_isBoilerplateOrCandidateName(cleanComp, candidateName, userName) || _isEducationOrCertificationLine(cleanComp)) {
          cleanComp = 'Software Enterprise';
        }
        if (_isBoilerplateOrCandidateName(cleanTitl, candidateName, userName) || _isEducationOrCertificationLine(cleanTitl)) {
          cleanTitl = 'Software Engineer';
        }

        if (!_isRawXmlOrBinary(cleanComp) && !_isRawXmlOrBinary(cleanTitl)) {
          results.add(
            WorkExperience(
              id: 'exp_${DateTime.now().millisecondsSinceEpoch}_${results.length + 1}',
              company: cleanComp.isNotEmpty ? cleanComp : 'Software Enterprise',
              title: cleanTitl.isNotEmpty ? cleanTitl : 'Software Engineer',
              location: 'Remote / On-site',
              startDate: currentStartDate.isNotEmpty ? currentStartDate : '2021',
              endDate: currentEndDate.isNotEmpty ? currentEndDate : 'Present',
              isCurrent: currentIsCurrent,
              bullets: List.from(currentBullets),
            ),
          );
        }
        currentCompany = '';
        currentTitle = '';
        currentStartDate = '';
        currentEndDate = '';
        currentIsCurrent = false;
        currentBullets.clear();
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final line = _cleanXmlTags(rawLine);
      final lower = line.toLowerCase();

      if (_isRawXmlOrBinary(line)) continue;

      if (lower.contains('education') || lower.contains('academic background') || lower.contains('certifications') || lower.contains('qualifications')) {
        inEducationSection = true;
        commitCurrentExp();
        continue;
      }

      if (lower.contains('experience') || lower.contains('employment') || lower.contains('work history')) {
        inEducationSection = false;
      }

      if (inEducationSection ||
          _isEducationOrCertificationLine(line) ||
          _isLinkLine(line) ||
          _isBoilerplateOrCandidateName(line, candidateName, userName)) {
        continue;
      }

      final dateMatch = dateRegex.firstMatch(line);

      if (dateMatch != null) {
        if (currentBullets.isNotEmpty) commitCurrentExp();

        final dateStr = dateMatch.group(0)!;
        final parts = dateStr.split(RegExp(r'[-–]'));
        currentStartDate = parts.isNotEmpty ? parts.first.trim() : '2020';
        currentEndDate = parts.length > 1 ? parts.last.trim() : 'Present';
        currentIsCurrent = currentEndDate.toLowerCase().contains('present') || currentEndDate.toLowerCase().contains('current');

        if (i > 0 && !_isLinkLine(lines[i - 1]) && !_isEducationOrCertificationLine(lines[i - 1]) && !_isBoilerplateOrCandidateName(lines[i - 1], candidateName, userName)) {
          currentTitle = _cleanXmlTags(lines[i - 1]);
        }
        currentCompany = line.replaceAll(dateStr, '').replaceAll(RegExp(r'[|•\-]'), '').trim();
      } else if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || line.length > 20) {
        final text = _cleanXmlTags(line.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''));
        if (text.isNotEmpty &&
            !text.contains('@') &&
            !_isLinkLine(text) &&
            !_isEducationOrCertificationLine(text) &&
            !_isBoilerplateOrCandidateName(text, candidateName, userName) &&
            !_isRawXmlOrBinary(text)) {
          currentBullets.add(
            ExperienceBullet(
              id: 'b_${DateTime.now().millisecondsSinceEpoch}_${currentBullets.length + 1}',
              text: text,
            ),
          );
        }
      }
    }

    commitCurrentExp();
    return results;
  }

  static List<SkillItem> _extractSkills(String text) {
    final Set<SkillItem> found = {};

    void checkTaxonomy(Set<String> set, SkillCategory cat) {
      for (final skill in set) {
        final regex = RegExp(r'\b' + RegExp.escape(skill) + r'\b', caseSensitive: false);
        if (regex.hasMatch(text)) {
          found.add(
            SkillItem(
              id: 'sk_${skill.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
              name: skill,
              category: cat,
            ),
          );
        }
      }
    }

    checkTaxonomy(_knownTechnicalSkills, SkillCategory.hard);
    checkTaxonomy(_knownToolSkills, SkillCategory.tool);
    checkTaxonomy(_knownSoftSkills, SkillCategory.soft);

    if (found.isEmpty) {
      found.addAll([
        SkillItem(id: 'sk1', name: 'Software Engineering', category: SkillCategory.hard),
        SkillItem(id: 'sk2', name: 'Problem Solving', category: SkillCategory.soft),
        SkillItem(id: 'sk3', name: 'Git', category: SkillCategory.tool),
      ]);
    }

    return found.toList();
  }

  static List<EducationEntry> _extractEducation(List<String> lines) {
    final results = <EducationEntry>[];
    for (int i = 0; i < lines.length; i++) {
      final line = _cleanXmlTags(lines[i]);
      if (_isEducationOrCertificationLine(line) && !_isRawXmlOrBinary(line)) {
        var institution = (i > 0 && !lines[i - 1].contains('@') && !_isLinkLine(lines[i - 1]))
            ? _cleanXmlTags(lines[i - 1])
            : 'Education / Certification Provider';

        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('cisco')) {
          institution = 'Cisco Networking Academy';
        } else if (lowerLine.contains('coursera')) {
          institution = 'Coursera';
        } else if (lowerLine.contains('udemy')) {
          institution = 'Udemy';
        } else if (lowerLine.contains('aws')) {
          institution = 'Amazon Web Services (AWS)';
        }

        if (_isRawXmlOrBinary(institution)) {
          institution = 'Certification Provider';
        }

        final endYearMatch = RegExp(r'\b(20\d{2}|19\d{2})\b').firstMatch(line);
        final isCert = lowerLine.contains('cisco') || lowerLine.contains('essentials') || lowerLine.contains('certificate') || lowerLine.contains('cybersecurity');

        results.add(
          EducationEntry(
            id: 'edu_${results.length + 1}',
            institution: institution,
            degree: line,
            fieldOfStudy: isCert ? 'Professional Certification' : 'Computer Science & Software Engineering',
            startYear: '2020',
            endYear: endYearMatch?.group(0) ?? '2023',
          ),
        );
      }
    }

    return results;
  }
}
