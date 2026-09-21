import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/feed_api.dart';
import '../models/feed_model.dart';

// ── Topics ────────────────────────────────────────────────────────────────────

class FeedTopicsNotifier extends AsyncNotifier<List<FeedTopic>> {
  @override
  Future<List<FeedTopic>> build() => _fetch();

  Future<List<FeedTopic>> _fetch() async {
    final api = ref.read(feedApiProvider);
    final res = await api.getTopics();
    final list = res.data as List;
    return list.map((e) => FeedTopic.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> follow(String topicId) async {
    await ref.read(feedApiProvider).followTopic(topicId);
    state = state.whenData((topics) => topics
        .map((t) => t.id == topicId ? t.copyWith(isFollowing: true) : t)
        .toList());
  }

  Future<void> unfollow(String topicId) async {
    await ref.read(feedApiProvider).unfollowTopic(topicId);
    state = state.whenData((topics) => topics
        .map((t) => t.id == topicId ? t.copyWith(isFollowing: false) : t)
        .toList());
  }

  Future<void> createTopic(String title, String description) async {
    final api = ref.read(feedApiProvider);
    await api.createTopic(title: title, description: description);
    await refresh();
  }

  Future<void> deleteTopic(String topicId) async {
    await ref.read(feedApiProvider).deleteTopic(topicId);
    state = state.whenData(
        (topics) => topics.where((t) => t.id != topicId).toList());
  }
}

final feedTopicsProvider =
    AsyncNotifierProvider<FeedTopicsNotifier, List<FeedTopic>>(
        FeedTopicsNotifier.new);

// ── Posts (per-topic, simple FutureProvider.family) ───────────────────────────

final feedPostsProvider =
    FutureProvider.family<List<FeedPost>, String>((ref, topicId) async {
  final api = ref.read(feedApiProvider);
  final res = await api.getPosts(topicId);
  final list = res.data as List;
  return list
      .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
      .toList();
});
