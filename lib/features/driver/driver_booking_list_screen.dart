import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking_model.dart';
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

    // 🔥 CRITICAL FIX:
    // Ensure fresh fetch whenever screen is opened
    Future.microtask(() {
      ref.invalidate(driverBookingsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(driverBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load bookings')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'No pending booking requests',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (_, index) {
              return _BookingRequestCard(
                booking: bookings[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingRequestCard extends ConsumerWidget {
  final Booking booking;

  const _BookingRequestCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(driverBookingsProvider.notifier);
    final isProcessing = notifier.isProcessing(booking.id);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.passengerName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              booking.pickup.toString(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 🔄 Spinner per booking
            if (isProcessing)
              const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
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
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
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
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
          ],
        ),
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
