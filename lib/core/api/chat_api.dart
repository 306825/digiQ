import 'package:dio/dio.dart';
import 'package:digiQ/models/chat_message_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

class ChatApi {
  final Dio dio;
  ChatApi(this.dio);

  Future<List<ChatMessage>> getHistory(String bookingId, {DateTime? since}) async {
    final response = await dio.get(
      '/chat/$bookingId',
      queryParameters: since != null
          ? {'since': since.toUtc().toIso8601String()}
          : null,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage(String bookingId, String text) async {
    final response = await dio.post('/chat/$bookingId', data: {'text': text});
    return ChatMessage.fromJson(response.data as Map<String, dynamic>);
  }
}

final chatApiProvider = Provider<ChatApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return ChatApi(dio);
});
