import 'package:digiQ/core/api/admin_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _pendingPassengerVerificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(adminApiProvider);
  return api.getPendingPassengerVerifications();
});

class AdminPassengerVerificationsTab extends ConsumerWidget {
  const AdminPassengerVerificationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_pendingPassengerVerificationsProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load verification requests.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  ref.invalidate(_pendingPassengerVerificationsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (items) => items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No pending verifications',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(_pendingPassengerVerificationsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _VerificationCard(item: items[i], ref: ref),
              ),
            ),
    );
  }
}

class _VerificationCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final WidgetRef ref;

  const _VerificationCard({required this.item, required this.ref});

  @override
  State<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends State<_VerificationCard> {
  bool _loading = false;

  Map<String, dynamic> get item => widget.item;
  Map<String, dynamic> get passenger =>
      (item['passenger'] as Map<String, dynamic>? ?? {});

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await widget.ref
          .read(adminApiProvider)
          .approvePassengerVerification(item['userId'] as String);
      widget.ref.invalidate(_pendingPassengerVerificationsProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve. Please try again.')),
        );
      }
    }
  }

  Future<void> _reject() async {
    final reason = await _showRejectDialog(context);
    if (reason == null) return;
    setState(() => _loading = true);
    try {
      await widget.ref
          .read(adminApiProvider)
          .rejectPassengerVerification(item['userId'] as String,
              reason: reason.trim().isEmpty ? null : reason.trim());
      widget.ref.invalidate(_pendingPassengerVerificationsProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfieUrl = item['selfieUrl'] as String?;
    final submittedAt = item['submittedAt'] as String?;
    final dateLabel = submittedAt != null
        ? DateFormat('d MMM y, HH:mm')
            .format(DateTime.parse(submittedAt).toLocal())
        : 'Unknown date';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Passenger info row
            Row(
              children: [
                _Avatar(url: passenger['profileImageUrl'] as String?),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger['fullName'] as String? ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        passenger['email'] as String? ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(
              'Submitted $dateLabel',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),

            const SizedBox(height: 14),

            // Selfie
            if (selfieUrl != null)
              GestureDetector(
                onTap: () => _showFullImage(context, selfieUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    selfieUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.grey),
                      ),
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : SizedBox(
                            height: 220,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          ),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child:
                      Text('No selfie available', style: TextStyle(color: Colors.grey)),
                ),
              ),

            const SizedBox(height: 14),

            // Action buttons
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16,
                          color: Colors.red),
                      label: const Text('Reject',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: _reject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade600),
                      onPressed: _approve,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

Future<String?> _showRejectDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reject Verification'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Reason (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String? url;

  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(radius: 24, backgroundImage: NetworkImage(url!));
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade200,
      child: const Icon(Icons.person_outline, color: Colors.grey),
    );
  }
}
