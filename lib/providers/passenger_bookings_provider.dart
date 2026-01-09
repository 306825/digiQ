import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/booking_api.dart';
import '../models/booking_model.dart';

class PassengerBookingsNotifier extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final api = ref.read(bookingApiProvider);

    final response = await api.getMyBookings();

    final List<dynamic> list = response.data as List<dynamic>;

    return list.map((json) => Booking.fromJson(json)).toList();
  }

  /// Optional manual refresh (future-proof)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final passengerBookingsProvider =
    AsyncNotifierProvider<PassengerBookingsNotifier, List<Booking>>(
  PassengerBookingsNotifier.new,
);
