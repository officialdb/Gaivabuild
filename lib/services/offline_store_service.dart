import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tailored_application.dart';
import 'auth_service.dart';

class OfflineStoreService {
  static const String _keyProfile = 'cached_master_profile_v1';
  static const String _keyPendingApps = 'pending_offline_applications_queue_v1';

  /// Saves local Master Profile JSON snapshot for offline availability
  static Future<void> saveCachedProfile(Map<String, dynamic> profileJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profileJson));
  }

  /// Retrieves local cached Master Profile when offline
  static Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Enqueues application generated while offline (flights / subways)
  static Future<void> queueOfflineApplication(TailoredJobApplication app) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyPendingApps) ?? [];
    rawList.add(jsonEncode(app.toJson()));
    await prefs.setStringList(_keyPendingApps, rawList);
  }

  /// Synchronizes all pending offline applications to Auth Postgres backend
  static Future<int> syncPendingOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyPendingApps) ?? [];
    if (rawList.isEmpty) return 0;

    int syncedCount = 0;
    final remaining = <String>[];

    for (final jsonStr in rawList) {
      try {
        final Map<String, dynamic> item = jsonDecode(jsonStr);
        final app = TailoredJobApplication.fromJson(item);
        await AuthService().insertTailoredApplication(
          jobTitle: app.jobTitle,
          targetCompany: app.targetCompany,
          rawJd: app.rawJobDescription,
          tone: app.tone,
          atsScore: app.atsMatchScore,
          matchedKeywords: app.matchedKeywords,
          missingKeywords: app.missingKeywords,
          sections: app.sections.map((s) => s.toJson()).toList(),
        );
        syncedCount++;
      } catch (_) {
        // Keep in queue to retry on next sync if network fails
        remaining.add(jsonStr);
      }
    }

    await prefs.setStringList(_keyPendingApps, remaining);
    return syncedCount;
  }

  /// Returns count of items waiting in offline sync queue
  static Future<int> getPendingQueueCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyPendingApps) ?? []).length;
  }
}

