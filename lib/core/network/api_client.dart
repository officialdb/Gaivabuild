import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  final _storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final response = await _client.get(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders());
    return _handleResponse(response);
  }

  Future<http.Response> post(String endpoint, {dynamic body, bool isUrlEncoded = false}) async {
    final headers = await _getHeaders();
    if (isUrlEncoded) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: isUrlEncoded ? body : (body != null ? jsonEncode(body) : null),
    );
    return _handleResponse(response);
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await _client.put(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders(), body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await _client.delete(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders());
    return _handleResponse(response);
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    String errorMsg = 'An error occurred';
    try {
      errorMsg = jsonDecode(response.body)['detail'] ?? errorMsg;
    } catch (_) {}
    throw ApiException(response.statusCode, errorMsg);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  
  @override
  String toString() => message;
}

