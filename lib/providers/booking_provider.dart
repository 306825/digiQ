import 'package:flutter_riverpod/legacy.dart';
//import 'package:state_notifier/state_notifier.dart';
import 'package:digiQ/models/booking_model.dart';

/// UI-only booking state (loading / success / error).
/// Business booking state lives in bookings_store_provider.dart
enum BookingResult { idle, loading, success, error }

class BookingState {
  final BookingResult result;
  final String? errorMessage;

  const BookingState({this.result = BookingResult.idle, this.errorMessage});

  bool get isLoading => result == BookingResult.loading;
}

class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier() : super(const BookingState());

  Future<void> createBooking({
    required String tripId,
    required PickupAddress pickup,
    required int seatCount,
  }) async {
    state = const BookingState(result: BookingResult.loading);

    try {
      // TEMP: simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // NOTE: real persistence handled elsewhere (bookingsStoreProvider)

      state = const BookingState(result: BookingResult.success);
    } catch (_) {
      state = const BookingState(
        result: BookingResult.error,
        errorMessage: 'Failed to create booking',
      );
    }
  }

  void reset() {
    state = const BookingState();
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>(
  (ref) => BookingNotifier(),
);
