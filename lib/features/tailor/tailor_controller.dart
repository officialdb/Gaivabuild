import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TailorGenerationState {
  final int progress;
  final String statusMessage;
  final Map<String, dynamic>? finalResponse;

  TailorGenerationState({this.progress = 0, this.statusMessage = '', this.finalResponse});
}

final tailorControllerProvider = StateNotifierProvider<TailorController, TailorGenerationState>((ref) {
  return TailorController();
});

class TailorController extends StateNotifier<TailorGenerationState> {
  TailorController() : super(TailorGenerationState());
  
  void startStream(String jobDescription) async {
    state = TailorGenerationState(progress: 5, statusMessage: 'Connecting...');
    final token = await const FlutterSecureStorage().read(key: 'jwt_token');

    SSEClient.subscribeToSSE(
      method: SSERequestType.POST,
      url: 'http://127.0.0.1:8000/api/v1/cv/tailor/stream',
      header: {
        "Authorization": "Bearer $token",
        "Accept": "text/event-stream",
        "Content-Type": "application/json"
      },
      body: {"job_description": jobDescription},
    ).listen((event) {
      if (event.data != null && event.data!.isNotEmpty) {
        final data = jsonDecode(event.data!);
        state = TailorGenerationState(
          progress: data['progress'] ?? state.progress,
          statusMessage: data['status'] ?? state.statusMessage,
          finalResponse: data['result'], // Populated when progress == 100
        );
      }
    });
  }

  void cancelStream() {
    SSEClient.unsubscribeFromSSE();
    state = TailorGenerationState(); // Reset
  }
}

