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
      final api = ref.read(bookingApiProvider);
      final response = await api.getPendingBookings();
      final list = response.data as List<dynamic>;
      return list.map((e) => DriverBooking.fromJson(e)).toList();
    } catch (e) {

      if (e is DioException && e.response?.statusCode == 403) {
        final body = e.response?.data;
        final code = body is Map ? body['code'] : null;
        if (code == 'VEHICLE_NOT_APPROVED') {
          throw Exception('Your vehicle must be approved before you can receive bookings.');
        }
        throw Exception('Access denied. Please contact support.');
      }

      rethrow;
    }
  }

  bool isProcessing(String bookingId) => _processing.contains(bookingId);

  // Refresh without clearing existing state — badge stays visible during fetch
  Future<void> silentRefresh() async {
    final fresh = await AsyncValue.guard(build);
    state = fresh;
  }

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
