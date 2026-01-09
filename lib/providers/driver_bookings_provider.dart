import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/booking_api.dart';
import '../models/booking_model.dart';

class DriverBookingsNotifier extends AsyncNotifier<List<Booking>> {
  final Set<String> _processing = {};

  @override
  Future<List<Booking>> build() async {
    final api = ref.read(bookingApiProvider);
    final response = await api.getPendingBookings();
    final list = response.data as List<dynamic>;
    return list.map((e) => Booking.fromJson(e)).toList();
  }

  bool isProcessing(String bookingId) => _processing.contains(bookingId);

  Future<void> respond({
    required String bookingId,
    required BookingStatus status,
  }) async {
    _processing.add(bookingId);

    // force UI rebuild so spinner shows
    state = AsyncData([...state.value ?? []]);

    try {
      await ref.read(bookingApiProvider).updateBookingStatus(
            bookingId: bookingId,
            status: status.name,
          );

      // remove booking ONLY after backend success
      state = AsyncData(
        state.value!.where((b) => b.id != bookingId).toList(),
      );
    } finally {
      _processing.remove(bookingId);
    }
  }
}

final driverBookingsProvider =
    AsyncNotifierProvider<DriverBookingsNotifier, List<Booking>>(
  DriverBookingsNotifier.new,
);
