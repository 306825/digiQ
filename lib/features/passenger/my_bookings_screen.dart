import 'package:digiQ/models/booking_model.dart';
import 'package:digiQ/models/booking_status_ui.dart';
import 'package:digiQ/providers/passenger_bookings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(passengerBookingsProvider);
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(passengerBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _ErrorState(),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(passengerBookingsProvider.notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                return _BookingCard(
                  booking: bookings[index],
                  updatedAtLabel: _formatDate(bookings[index].updatedAt),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Booking Card
 * -------------------------------------------------------------------------- */

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  final String updatedAtLabel;

  const _BookingCard({
    required this.booking,
    required this.updatedAtLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = booking.status;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📍 Pickup
            Text(
              booking.pickup.addressLine,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.pickup.area,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 12),

            // 🟡 Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(status: status),
                Text(
                  'Updated $updatedAtLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            // 🔴 Actions
            if (status == BookingStatus.pending) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _CancelButton(bookingId: booking.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Status Chip
 * -------------------------------------------------------------------------- */

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Cancel Button
 * -------------------------------------------------------------------------- */

class _CancelButton extends ConsumerWidget {
  final String bookingId;

  const _CancelButton({required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(passengerBookingsProvider.notifier);
    final isProcessing = notifier.isProcessing(bookingId);

    if (isProcessing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return TextButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cancel booking?'),
            content: const Text(
              'This booking has not been accepted yet.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep booking'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cancel booking'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        await notifier.cancel(bookingId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled')),
          );
        }
      },
      child: const Text(
        'Cancel',
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Empty + Error States
 * -------------------------------------------------------------------------- */

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.event_seat, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When you book a trip, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline, size: 56, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Failed to load bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
