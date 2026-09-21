import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

class FeedApi {
  final Dio dio;
  FeedApi(this.dio);

  Future<Response> getTopics() => dio.get('/feed/topics');

  Future<Response> createTopic({required String title, required String description}) =>
      dio.post('/feed/topics', data: {'title': title, 'description': description});

  Future<Response> deleteTopic(String topicId) => dio.delete('/feed/topics/$topicId');

  Future<Response> followTopic(String topicId) => dio.post('/feed/topics/$topicId/follow');

  Future<Response> unfollowTopic(String topicId) => dio.delete('/feed/topics/$topicId/follow');

  Future<Response> getPosts(String topicId) => dio.get('/feed/topics/$topicId/posts');

  Future<Response> createPost({
    required String topicId,
    required String title,
    required String body,
  }) =>
      dio.post('/feed/topics/$topicId/posts', data: {'title': title, 'postBody': body});
}

final feedApiProvider = Provider<FeedApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return FeedApi(dio);
});
