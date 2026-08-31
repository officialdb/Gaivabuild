import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_controller.dart';

final accountControllerProvider = Provider((ref) => AccountController(ref));

class AccountController {
  final Ref ref;
  AccountController(this.ref);

  Future<String> softDeleteAccount() async {
    final api = ApiClient();
    try {
      final response = await api.delete('/account/');
      final message = jsonDecode(response.body)['message'];
      
      // Clear token and logout locally
      await ref.read(authControllerProvider.notifier).logout();
      
      return message; // Return the 30-day retention message for the Snackbar
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}

