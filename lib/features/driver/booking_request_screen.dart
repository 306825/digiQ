import 'package:digiQ/features/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/driver_booking_review_provider.dart';

class BookingRequestScreen extends ConsumerWidget {
  final String bookingId;
  final String address;
  final String area;
  final String? notes;

  const BookingRequestScreen({
    super.key,
    required this.bookingId,
    required this.address,
    required this.area,
    this.notes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(driverBookingReviewProvider);

    Future<void> respond(bool accepted) async {
      await ref
          .read(driverBookingReviewProvider.notifier)
          .respondToBooking(bookingId: bookingId, accepted: accepted);

      if (context.mounted) {
        Navigator.pop(context);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Request")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Passenger Pickup",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(address),
                Text(area),
                if (notes != null && notes!.isNotEmpty) Text("Notes: $notes"),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: "Accept",
                        isLoading: isLoading,
                        onPressed: () => respond(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => respond(false),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
