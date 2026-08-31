import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/master_profile.dart';
import '../models/tailored_application.dart';

class AiTailoringService {
  static final String baseUrl = !kIsWeb && Platform.isAndroid 
      ? 'https://gaivabuild-production.up.railway.app' 
      : 'https://gaivabuild-production.up.railway.app';

  static Future<TailoredJobApplication> generateTailoredApplication({
    required String jobTitle,
    required String company,
    required String rawJd,
    required MasterProfile masterProfile,
    String tone = 'Professional',
  }) async {
    final userProfileData = '''
Name: ${masterProfile.fullName}
Title: ${masterProfile.title}
Skills: ${masterProfile.skills.map((s) => s.name).join(", ")}
Work Experiences:
${masterProfile.experiences.map((exp) => "Role: ${exp.title} at ${exp.company} (${exp.startDate} - ${exp.endDate})\nBullets:\n${exp.bullets.map((b) => "- ${b.text}").join("\n")}").join("\n\n")}
''';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-cv'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'job_title': jobTitle,
          'target_company': company,
          'tone': tone,
          'raw_jd': rawJd,
          'user_profile_data': userProfileData,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final parsedContent = jsonDecode(response.body) as Map<String, dynamic>;
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
