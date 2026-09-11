import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/core/api/api_providers.dart';

final adminFeedbackProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(adminApiProvider);
  return api.getFeedback();
});

class AdminFeedbackTab extends ConsumerWidget {
  const AdminFeedbackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(adminFeedbackProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminFeedbackProvider),
      child: feedbackAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load feedback: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No feedback submitted yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) => _FeedbackCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _FeedbackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final category = item['category'] as String? ?? 'other';
    final message = item['message'] as String? ?? '';
    final userName = item['userName'] as String? ?? 'Unknown';
    final userRole = item['userRole'] as String? ?? '';
    final appVersion = item['appVersion'] as String? ?? '';
    final platform = item['platform'] as String? ?? '';
    final submittedAt = item['submittedAt'] != null
        ? DateTime.tryParse(item['submittedAt'].toString())
        : null;

    final (icon, color, label) = switch (category) {
      'bug' => (Icons.bug_report_outlined, Colors.red, 'Bug Report'),
      'idea' => (Icons.lightbulb_outline, Colors.amber.shade700, 'Feature Idea'),
      _ => (Icons.chat_bubble_outline, Colors.blue, 'General'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                if (submittedAt != null)
                  Text(
                    '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '$userName · $userRole',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  '$platform · v$appVersion',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
