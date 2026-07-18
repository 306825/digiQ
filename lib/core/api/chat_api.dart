import 'package:dio/dio.dart';
import 'package:digiQ/models/chat_message_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

class ChatApi {
  final Dio dio;
  ChatApi(this.dio);

  Future<List<ChatMessage>> getHistory(String bookingId) async {
    final response = await dio.get('/chat/$bookingId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final chatApiProvider = Provider<ChatApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return ChatApi(dio);
});
