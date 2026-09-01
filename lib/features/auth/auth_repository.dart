import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(ApiClient()));

class AuthRepository {
  final ApiClient _api;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._api);

  Future<void> login(String email, String password) async {
    final response = await _api.post('/auth/login', body: {
      'username': email,
      'password': password,
    }, isUrlEncoded: true);

    final data = jsonDecode(response.body);
    await _storage.write(key: 'jwt_token', value: data['access_token']);
  }

  Future<void> register(String email, String password, {String? fullName}) async {
    final reqBody = {'email': email, 'password': password};
    if (fullName != null) reqBody['full_name'] = fullName;
    await _api.post('/auth/register', body: reqBody);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', body: {'email': email});
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}

