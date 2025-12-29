import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bookings_store_provider.dart';
import '../../models/booking_entity.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsStoreProvider);

    if (bookings.isEmpty) {
      return const Scaffold(body: Center(child: Text('No bookings yet')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (_, index) {
          final booking = bookings[index];

          return ListTile(
            title: Text(booking.pickupAddress),
            subtitle: Text(
              booking.status.name.toUpperCase(),
              style: TextStyle(
                color: booking.status == BookingStatus.confirmed
                    ? Colors.green
                    : booking.status == BookingStatus.rejected
                    ? Colors.red
                    : Colors.orange,
              ),
            ),
          );
        },
      ),
    );
  }
}
