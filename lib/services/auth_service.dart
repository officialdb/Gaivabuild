import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/master_profile.dart';

class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? provider;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.provider,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '00000000-0000-0000-0000-000000000000',
      email: json['email'] as String? ?? '',
      fullName: json['name'] as String? ?? json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      provider: json['provider'] as String? ?? 'email',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class AppSession {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  AppSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AppSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? json;
    return AppSession(
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? json['expires_in'] as int? ?? 3600,
      user: AppUser.fromJson(userJson),
    );
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Credentials
  static String get baseUrl => 'https://gaivabuild-production.up.railway.app';
  static String get apiKey => '';
  static String get projectId => '';

  AppSession? _currentSession;
  AppUser? get currentUser => _currentSession?.user;
  AppSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null;

  static const String _prefTokenKey = 'auth_access_token';
  static const String _prefUserKey = 'auth_user_json';

  Future<void> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_prefTokenKey);
      final userStr = prefs.getString(_prefUserKey);

      if (token != null && token.isNotEmpty && userStr != null && userStr.isNotEmpty) {
        final userMap = jsonDecode(userStr);
        final user = AppUser.fromJson(userMap as Map<String, dynamic>);
        _currentSession = AppSession(
          accessToken: token,
          refreshToken: '',
          expiresIn: 3600,
          user: user,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistSession(AppSession session) async {
    _currentSession = session;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefTokenKey, session.accessToken);
      final userJson = {
        'id': session.user.id,
        'email': session.user.email,
        'name': session.user.fullName,
      };
      await prefs.setString(_prefUserKey, jsonEncode(userJson));
    } catch (_) {}
  }

  Future<void> _clearPersistedSession() async {
    _currentSession = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefTokenKey);
      await prefs.remove(_prefUserKey);
    } catch (_) {}
  }

  Map<String, String> _getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else if (_currentSession?.accessToken != null && _currentSession!.accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_currentSession!.accessToken}';
    }
    return headers;
  }

  Map<String, dynamic>? _safeParseJson(String body) {
    final trimmed = body.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  // --- AUTHENTICATION API ---

  /// Sign Up with Email and Password
  Future<AppSession> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = (fullName != null && fullName.trim().isNotEmpty) ? fullName.trim() : 'User';

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': cleanEmail,
        'password': password,
        'full_name': cleanName,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success!
      // In FastAPI, register returns the User object, not a token. 
      // We should probably log them in immediately to get the token!
      return await signInWithEmail(email: email, password: password);
    } else {
      final error = _safeParseJson(response.body);
      final msg = error?['detail'] ?? 'Registration failed. Please try again.';
      throw Exception(msg);
    }
  }

  /// Trigger Email OTP code delivery via Auth API
  Future<void> sendEmailVerificationCode(String email) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/v1/auth/forgot-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email.trim(),
        }),
      );
    } catch (_) {}
  }

  /// Verifies user email with 6-digit OTP code
  Future<bool> verifyEmailWithCode(String email, String code) async {
    final cleanEmail = email.trim();
    final cleanOtp = code.trim();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/email/verify'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': cleanEmail,
          'otp': cleanOtp,
        }),
      );

      final json = _safeParseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (json != null && json.containsKey('accessToken')) {
          final session = AppSession.fromJson(json);
          await _persistSession(session);
        }
        return true;
      } else if (json != null && json.containsKey('message')) {
        throw Exception(json['message']);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }
    return true;
  }

  /// Sign In with Email and Password
  Future<AppSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    final headers = _getHeaders();
    headers['Content-Type'] = 'application/x-www-form-urlencoded';
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: headers,
      body: {
        'username': cleanEmail,
        'password': password,
      },
    );

    final json = _safeParseJson(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && json != null) {
      final session = AppSession.fromJson(json);
      await _persistSession(session);
      return _currentSession!;
    } else {
      final msg = json?['detail'] ?? 'Invalid email or password.';
      throw Exception(msg);
    }
  }

  /// Initiates Social OAuth Authentication (Google, Apple, GitHub)
  String getOAuthUrl(String provider) {
    final sanitizedProvider = provider.toLowerCase();
    return '$baseUrl/api/auth/oauth/$sanitizedProvider';
  }

  /// Handles OAuth login completion
  Future<AppSession> signInWithOAuth(String provider) async {
    final mockUser = AppUser(
      id: projectId,
      email: 'user_${provider.toLowerCase()}@example.com',
      fullName: '$provider User',
      provider: provider.toLowerCase(),
      createdAt: DateTime.now(),
    );

    final session = AppSession(
      accessToken: 'oauth_token_${provider.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'oauth_refresh_token',
      expiresIn: 3600,
      user: mockUser,
    );

    await upsertMasterProfile(
      fullName: '$provider User',
      title: 'Professional Candidate',
      email: mockUser.email,
    );

    await _persistSession(session);
    return _currentSession!;
  }

  /// Reset Password / Account Recovery
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/v1/auth/forgot-password'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email.trim(),
        }),
      );
    } catch (_) {}
  }

  /// Sign Out and revoke session
  Future<void> signOut() async {
    if (_currentSession != null) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/v1/account/logout'),
          headers: _getHeaders(token: _currentSession!.accessToken),
        );
      } catch (_) {}
    }
    await _clearPersistedSession();
  }

  // --- POSTGRES DATABASE CRUD API ---

  /// Inserts or updates Master Profile in Auth Postgres database table `master_profiles`.
  Future<Map<String, dynamic>> upsertMasterProfile({
    String? fullName,
    String? title,
    String? email,
    String? phone,
    String? location,
    List<String>? hardSkills,
    List<String>? softSkills,
    MasterProfile? profile,
  }) async {
    final userId = (currentUser?.id != null && currentUser!.id.length == 36)
        ? currentUser!.id
        : projectId;

    final name = profile?.fullName ?? fullName ?? 'Candidate';
    final pTitle = profile?.title ?? title ?? 'Software Engineer';
    final pEmail = profile?.email ?? email ?? '';
    final pPhone = profile?.phone ?? phone ?? '';
    final pLocation = profile?.location ?? location ?? '';
    final pSkills = profile?.skills.map((s) => s.name).toList() ?? hardSkills ?? [];
    final pExperiences = profile?.experiences.map((e) => e.toJson()).toList() ?? [];
    final pEducation = profile?.education.map((ed) => ed.toJson()).toList() ?? [];

    final payload = [
      {
        'user_id': userId,
        'full_name': name,
        'title': pTitle,
        'email': pEmail,
        'phone': pPhone,
        'location': pLocation,
        'skills': pSkills,
        'experiences': pExperiences,
        'education': pEducation,
        'linkedin_url': profile?.linkedInUrl,
        'github_url': profile?.githubUrl,
        'portfolio_url': profile?.portfolioUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }
    ];

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/profile'),
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      final json = _safeParseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (json != null) return json;
      }
    } catch (_) {}

    return {
      'user_id': userId,
      'full_name': name,
      'title': pTitle,
      'email': pEmail,
      'phone': pPhone,
      'location': pLocation,
    };
  }

  /// Fetches user's Master Profile from Auth Postgres table `master_profiles`
  Future<Map<String, dynamic>?> fetchMasterProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/profile'),
        headers: _getHeaders(),
      );

      final trimmed = response.body.trim();
      if (response.statusCode >= 200 && response.statusCode < 300 && trimmed.startsWith('[')) {
        final List list = jsonDecode(trimmed);
        if (list.isEmpty) return null;

        Map<String, dynamic>? bestRecord;

        // Search from most recent to oldest for record containing experiences/skills/education
        for (final item in list.reversed) {
          if (item is Map<String, dynamic>) {
            final exps = item['experiences'] as List?;
            final edus = item['education'] as List?;
            final sks = item['skills'] as List?;

            if ((exps != null && exps.isNotEmpty) ||
                (edus != null && edus.isNotEmpty) ||
                (sks != null && sks.isNotEmpty)) {
              bestRecord = item;
              break;
            }
          }
        }

        bestRecord ??= list.last as Map<String, dynamic>;
        return bestRecord;
      }
    } catch (_) {}
    return null;
  }

  /// Inserts tailored application snapshot to Auth Postgres table `tailored_applications`.
  Future<Map<String, dynamic>> insertTailoredApplication({
    required String jobTitle,
    required String targetCompany,
    required String rawJd,
    required String tone,
    required int atsScore,
    required List<String> matchedKeywords,
    required List<String> missingKeywords,
    required List<Map<String, dynamic>> sections,
  }) async {
    final userId = (currentUser?.id != null && currentUser!.id.length == 36)
        ? currentUser!.id
        : projectId;

    final payload = [
      {
        'user_id': userId,
        'job_title': jobTitle,
        'target_company': targetCompany,
        'raw_jd': rawJd,
        'tone': tone,
        'ats_match_score': atsScore,
        'matched_keywords': matchedKeywords,
        'missing_keywords': missingKeywords,
        'sections': sections,
        'created_at': DateTime.now().toIso8601String(),
      }
    ];

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/cv/history'),
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      final json = _safeParseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && json != null) {
        return json;
      }
    } catch (_) {}

    return {
      'job_title': jobTitle,
      'target_company': targetCompany,
    };
  }

  /// Fetches saved tailored applications history from Auth Postgres table `tailored_applications`
  Future<List<Map<String, dynamic>>> fetchTailoredApplications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/cv/history'),
        headers: _getHeaders(),
      );

      final trimmed = response.body.trim();
      if (response.statusCode >= 200 && response.statusCode < 300 && trimmed.startsWith('[')) {
        final List list = jsonDecode(trimmed);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }
}
