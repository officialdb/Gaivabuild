import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/master_profile.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ResumeParserService {
  static final String baseUrl = !kIsWeb && Platform.isAndroid 
      ? 'https://gaivabuild-production.up.railway.app/api/v1' 
      : 'https://gaivabuild-production.up.railway.app/api/v1';

  static Future<MasterProfile> parseResumeDocument({
    required String fileName,
    required List<int> bytes,
    String? userEmail,
    String? userName,
  }) async {
    final token = AuthService().currentSession?.accessToken;
    if (token == null) throw Exception("Unauthorized: No session token");

    final uri = Uri.parse('$baseUrl/profile/parse-cv');
    final request = http.MultipartRequest('POST', uri);
    
    request.headers['Authorization'] = 'Bearer $token';
    
    // Determine mime type
    String mimeType = 'application/octet-stream';
    if (fileName.toLowerCase().endsWith('.pdf')) {
      mimeType = 'application/pdf';
    } else if (fileName.toLowerCase().endsWith('.docx')) {
      mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    
  static Future<MasterProfile> parseLinkedInUrl(String linkedinUrl) async {
    final token = AuthService().currentSession?.accessToken;
    if (token == null) throw Exception("Unauthorized: No session token");

    final uri = Uri.parse('$baseUrl/profile/parse-linkedin');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'url': linkedinUrl}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return MasterProfile.fromJson(jsonMap);
    } else {
      throw Exception('Failed to parse LinkedIn: ${response.statusCode} - ${response.body}');
    }
  }
}

    final mediaType = MediaType.parse(mimeType);
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: mediaType,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return MasterProfile.fromJson(jsonMap);
    } else {
      throw Exception('Failed to parse CV on backend: ${response.statusCode} - ${response.body}');
    
  static Future<MasterProfile> parseLinkedInUrl(String linkedinUrl) async {
    final token = AuthService().currentSession?.accessToken;
    if (token == null) throw Exception("Unauthorized: No session token");

    final uri = Uri.parse('$baseUrl/profile/parse-linkedin');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'url': linkedinUrl}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return MasterProfile.fromJson(jsonMap);
    } else {
      throw Exception('Failed to parse LinkedIn: ${response.statusCode} - ${response.body}');
    }
  }
}
  
  static Future<MasterProfile> parseLinkedInUrl(String linkedinUrl) async {
    final token = AuthService().currentSession?.accessToken;
    if (token == null) throw Exception("Unauthorized: No session token");

    final uri = Uri.parse('$baseUrl/profile/parse-linkedin');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'url': linkedinUrl}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return MasterProfile.fromJson(jsonMap);
    } else {
      throw Exception('Failed to parse LinkedIn: ${response.statusCode} - ${response.body}');
    }
  }
}

  static Future<MasterProfile> parseLinkedInUrl(String linkedinUrl) async {
    final token = AuthService().currentSession?.accessToken;
    if (token == null) throw Exception("Unauthorized: No session token");

    final uri = Uri.parse('$baseUrl/profile/parse-linkedin');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'url': linkedinUrl}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return MasterProfile.fromJson(jsonMap);
    } else {
      throw Exception('Failed to parse LinkedIn: ${response.statusCode} - ${response.body}');
    }
  }
}
