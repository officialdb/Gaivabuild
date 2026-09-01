import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/master_profile.dart';
import '../models/tailored_application.dart';
import 'auth_service.dart';

class AiTailoringService {
  static final String baseUrl = 'https://gaivabuild-production.up.railway.app';

  static Future<TailoredJobApplication> generateTailoredApplication({
    required String jobTitle,
    required String company,
    required String rawJd,
    required MasterProfile masterProfile,
    String tone = 'Professional',
  }) async {
    final token = AuthService().currentSession?.accessToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final userProfileData = '''
Name: ${masterProfile.fullName}
Title: ${masterProfile.title}
Bio: ${masterProfile.bio.isNotEmpty ? masterProfile.bio : 'Candidate Bio'}
Education: ${masterProfile.education.isNotEmpty ? masterProfile.education.map((e) => "${e.degree} at ${e.institution} (${e.startYear}-${e.endYear})").join(" | ") : 'B.S. Computer Science'}
Skills: ${masterProfile.skills.map((s) => s.name).join(", ")}
Work Experiences:
${masterProfile.experiences.map((exp) => "Role: ${exp.title} at ${exp.company} (${exp.startDate} - ${exp.endDate})\nBullets:\n${exp.bullets.map((b) => "- ${b.text}").join("\n")}").join("\n\n")}
''';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-cv'),
        headers: headers,
        body: jsonEncode({
          'job_title': jobTitle,
          'target_company': company,
          'tone': tone,
          'raw_jd': rawJd,
          'user_profile_data': userProfileData,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Invalid server response format');
        }
        final parsedContent = Map<String, dynamic>.from(decoded);
        parsedContent['raw_jd'] = rawJd;
        parsedContent['tone'] = tone;
        parsedContent['candidate_name'] = masterProfile.fullName;
        return TailoredJobApplication.fromJson(parsedContent);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
