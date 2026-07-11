import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/booking_api.dart';
import '../models/booking_model.dart';

class PassengerBookingsNotifier extends AsyncNotifier<List<Booking>> {
  final Set<String> _processing = {};

  @override
  Future<List<Booking>> build() async {
    final api = ref.read(bookingApiProvider);
    final response = await api.getMyBookings();
    final List<dynamic> list = response.data as List<dynamic>;
    return list.map((json) => Booking.fromJson(json)).toList();
  }

  bool isProcessing(String bookingId) => _processing.contains(bookingId);

  Future<bool> cancel(String bookingId) async {
    _processing.add(bookingId);
    state = AsyncData([...state.value ?? []]);

    try {
      final response = await ref.read(bookingApiProvider).cancelBooking(bookingId);
      final data = response.data;
      final refunded = data is Map ? (data['refunded'] as bool? ?? false) : false;

      state = AsyncData(
        state.value!.where((b) => b.id != bookingId).toList(),
      );
      return refunded;
    } on DioException catch (e) {
      debugPrint('[CANCEL] status=${e.response?.statusCode}');
      debugPrint('[CANCEL] body=${e.response?.data}');
      rethrow;
    } finally {
      _processing.remove(bookingId);
    }
  }

  // Future<void> refresh() async {
  //   state = const AsyncLoading();
  //   state = await AsyncValue.guard(build);
  // }
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final passengerBookingsProvider =
    AsyncNotifierProvider<PassengerBookingsNotifier, List<Booking>>(
  PassengerBookingsNotifier.new,
);
