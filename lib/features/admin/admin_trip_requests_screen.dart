import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/models/trip_request_model.dart';
import 'package:strut/providers/trip_requests_provider.dart';

class AdminTripRequestsScreen extends ConsumerWidget {
  const AdminTripRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(adminTripRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(adminTripRequestsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No trip requests yet',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _RequestCard(request: requests[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final TripRequestModel request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Color _statusColor(TripRequestStatus s) {
    switch (s) {
      case TripRequestStatus.pendingDeposit:
        return Colors.orange;
      case TripRequestStatus.depositSent:
        return Colors.blue;
      case TripRequestStatus.depositConfirmed:
        return Colors.purple;
      case TripRequestStatus.tripLinked:
        return Colors.green;
      case TripRequestStatus.cancelled:
        return Colors.grey;
    }
  }

  Future<void> _confirmDeposit() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminTripRequestsProvider.notifier)
          .confirmDeposit(widget.request.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkTrip() async {
    final controller = TextEditingController();
    final tripId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link a trip'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Trip ID',
            hintText: 'Paste the MongoDB trip _id',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Link')),
        ],
      ),
    );

    if (tripId == null || tripId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminTripRequestsProvider.notifier)
          .linkTrip(widget.request.id, tripId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: route + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${r.from} → ${r.to}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(r.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.status.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Details
            _Detail('Date', r.date),
            _Detail('Seats needed', '${r.seatsNeeded}'),
            _Detail('Deposit method',
                r.depositMethod == DepositMethod.eft ? 'EFT' : 'PayShap'),
            _Detail('Reference', r.depositReference),
            _Detail('Requested',
                '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}'),
            if (r.adminNotes != null && r.adminNotes!.isNotEmpty)
              _Detail('Notes', r.adminNotes!),

            // Actions
            if (!_busy) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (r.status == TripRequestStatus.depositSent)
                    ElevatedButton.icon(
                      onPressed: _confirmDeposit,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Confirm deposit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  if (r.status == TripRequestStatus.depositConfirmed)
                    ElevatedButton.icon(
                      onPressed: _linkTrip,
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('Link trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
