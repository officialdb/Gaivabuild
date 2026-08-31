import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  AuthController(this._repository) : super(const AsyncData(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repository.login(email, password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  Future<void> register(String email, String password, {String? fullName}) async {
    state = const AsyncLoading();
    try {
      await _repository.register(email, password, fullName: fullName);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> forgotPassword(String email) async {
    state = const AsyncLoading();
    try {
      await _repository.forgotPassword(email);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(null);
  }
}

