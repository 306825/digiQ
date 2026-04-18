import 'package:digiQ/models/booking_model.dart';
import 'package:digiQ/models/driver_booking_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/booking_api.dart';

class DriverBookingsNotifier extends AsyncNotifier<List<DriverBooking>> {
  final Set<String> _processing = {};

  @override
  Future<List<DriverBooking>> build() async {
    try {
      print('🚀 FETCHING BOOKINGS...');

      final api = ref.read(bookingApiProvider);
      final response = await api.getPendingBookings();

      print('✅ RESPONSE RECEIVED');
      print('📦 RAW: ${response.data}');

      final list = response.data as List<dynamic>;
      return list.map((e) => DriverBooking.fromJson(e)).toList();
    } catch (e, stack) {
      print('❌ BOOKINGS ERROR: $e');
      print(stack);

      if (e is DioException && e.response?.statusCode == 403) {
        print('⛔ Access denied - stopping retry loop');
        return []; // 🔥 THIS STOPS THE LOOP
      }

      rethrow; // only rethrow unexpected errors
    }
  }

  bool isProcessing(String bookingId) => _processing.contains(bookingId);

  Future<void> respond({
    required String bookingId,
    required BookingStatus status,
  }) async {
    _processing.add(bookingId);

    // Force rebuild so spinner shows
    state = AsyncData([...state.value ?? []]);

    try {
      await ref.read(bookingApiProvider).updateBookingStatus(
            bookingId: bookingId,
            status: status.name,
          );

      // 🔥 IMPORTANT:
      // Re-fetch pending bookings from backend
      // This removes:
      // - approved booking
      // - auto-rejected bookings
      state = const AsyncLoading();
      state = await AsyncValue.guard(build);
    } finally {
      _processing.remove(bookingId);
    }
  }
}

final driverBookingsProvider =
    AsyncNotifierProvider<DriverBookingsNotifier, List<DriverBooking>>(
  DriverBookingsNotifier.new,
);
