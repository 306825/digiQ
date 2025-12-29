import 'package:flutter_riverpod/legacy.dart';

final driverBookingReviewProvider =
    StateNotifierProvider<DriverBookingReviewNotifier, bool>(
      (ref) => DriverBookingReviewNotifier(),
    );

class DriverBookingReviewNotifier extends StateNotifier<bool> {
  DriverBookingReviewNotifier() : super(false);

  Future<void> respondToBooking({
    required String bookingId,
    required bool accepted,
  }) async {
    state = true; // loading

    try {
      // TODO: call POST /bookings/{id}/respond
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      state = false;
    }
  }
}
