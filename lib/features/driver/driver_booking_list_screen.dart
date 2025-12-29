import 'package:digiQ/models/booking_entity.dart';
import 'package:digiQ/providers/bookings_store_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverBookingListScreen extends ConsumerWidget {
  const DriverBookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsStoreProvider);
    debugPrint('DRIVER BOOKINGS COUNT: ${bookings.length}');
    final pendingBookings = bookings
        .where((b) => b.status == BookingStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests')),
      body: pendingBookings.isEmpty
          ? const Center(child: Text('No pending booking requests'))
          : ListView.builder(
              itemCount: pendingBookings.length,
              itemBuilder: (_, index) {
                final booking = pendingBookings[index];

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.passengerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(booking.pickupAddress),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(bookingsStoreProvider.notifier)
                                      .updateStatus(
                                        booking.id,
                                        BookingStatus.confirmed,
                                      );
                                },

                                child: const Text('Accept'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ref
                                      .read(bookingsStoreProvider.notifier)
                                      .updateStatus(
                                        booking.id,
                                        BookingStatus.rejected,
                                      );
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
              },
            ),
    );
  }
}
