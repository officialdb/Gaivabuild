import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../models/master_profile.dart'; // Assume models exist

final profileRepositoryProvider = Provider((ref) => ProfileRepository(ApiClient()));

final profileProvider = FutureProvider.autoDispose<MasterProfile>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.fetchProfile();
});

class ProfileRepository {
  final ApiClient _api;
  ProfileRepository(this._api);

  Future<MasterProfile> fetchProfile() async {
    final response = await _api.get('/profile');
    return MasterProfile.fromJson(jsonDecode(response.body));
  }

  Future<void> updateDetails(Map<String, dynamic> data) async {
    await _api.put('/profile/details', body: data);
  }

  Future<void> addExperience(Map<String, dynamic> data) async {
    await _api.post('/profile/experience', body: data);
  }
}

