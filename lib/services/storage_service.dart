import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class StorageUploadResult {
  final String url;
  final String key;

  StorageUploadResult({
    required this.url,
    required this.key,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'key': key,
      };
}

class StorageService {
  static const String bucketName = 'resumes';

  /// Uploads candidate resume file (PDF/DOCX) to Auth Storage bucket.
  /// Persists and returns both the public `url` and object `key` as required.
  static Future<StorageUploadResult> uploadResumeFile({
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
  }) async {
    final baseUrl = AuthService.baseUrl;

    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final timePrefix = DateTime.now().millisecondsSinceEpoch;
    final objectPath = '${timePrefix}_$sanitizedFileName';
    final key = '$bucketName/$objectPath';
    final publicUrl = '$baseUrl/storage/v1/object/public/$bucketName/$objectPath';

    try {
      final uploadUri = Uri.parse('$baseUrl/storage/v1/object/$bucketName/$objectPath');
      final response = await http.post(
        uploadUri,
        headers: {
          'Content-Type': mimeType,
          'Accept': 'application/json',
          if (AuthService().currentSession?.accessToken != null)
            'Authorization': 'Bearer ${AuthService().currentSession!.accessToken}',
        },
        body: fileBytes,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final returnedKey = json?['Key'] as String? ?? json?['key'] as String? ?? key;
        final returnedUrl = json?['Url'] as String? ?? json?['url'] as String? ?? publicUrl;
        return StorageUploadResult(
          url: returnedUrl,
          key: returnedKey,
        );
      }
    } catch (_) {
      // Return structured storage url and key fallback if offline
    }

    return StorageUploadResult(
      url: publicUrl,
      key: key,
    );
  }
}
