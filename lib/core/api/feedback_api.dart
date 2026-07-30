import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

class FeedbackApi {
  final Dio dio;
  FeedbackApi(this.dio);

  Future<void> submit({
    required String category,
    required String message,
    required String appVersion,
    required String platform,
  }) async {
    await dio.post('/feedback', data: {
      'category': category,
      'message': message,
      'appVersion': appVersion,
      'platform': platform,
    });
  }
}

final feedbackApiProvider = Provider<FeedbackApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return FeedbackApi(dio);
});
