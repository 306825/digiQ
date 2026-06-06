import 'package:digiQ/features/shared/widgets/user_avatar.dart';
import 'package:digiQ/models/booking_model.dart';
import 'package:digiQ/models/driver_booking_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/driver_bookings_provider.dart';

class DriverBookingListScreen extends ConsumerStatefulWidget {
  const DriverBookingListScreen({super.key});

  @override
  ConsumerState<DriverBookingListScreen> createState() =>
      _DriverBookingListScreenState();
}

class _DriverBookingListScreenState
    extends ConsumerState<DriverBookingListScreen> {
  @override
  void initState() {
    super.initState();
    // Always re-fetch when the screen opens so new bookings are visible
    Future.microtask(() {
      ref.invalidate(driverBookingsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(driverBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        centerTitle: true,
      ),
      body: bookingsAsync.when(
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(message: error.toString()),
        data: (bookings) {
          if (bookings.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(driverBookingsProvider),
              child: const _EmptyState(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(driverBookingsProvider),
            child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              return _BookingCard(booking: bookings[index]);
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
  final DriverBooking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(driverBookingsProvider.notifier);
    final isProcessing = notifier.isProcessing(booking.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger row
          Row(
            children: [
              UserAvatar(
                displayName: booking.passengerName,
                imageUrl: booking.passengerProfileImageUrl,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  booking.passengerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${booking.address}, ${booking.area}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (isProcessing)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    onPressed: () async {
                      try {
                        await notifier.respond(
                          bookingId: booking.id,
                          status: BookingStatus.approved,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking approved'),
                            ),
                          );
                        }
                      } catch (_) {
                        _showError(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    onPressed: () async {
                      try {
                        await notifier.respond(
                          bookingId: booking.id,
                          status: BookingStatus.rejected,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking rejected'),
                            ),
                          );
                        }
                      } catch (_) {
                        _showError(context);
                      }
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to update booking. Please try again.'),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * UI States
 * -------------------------------------------------------------------------- */

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  const _ErrorState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Could not load booking requests',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No booking requests yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When passengers request a seat, they’ll appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
