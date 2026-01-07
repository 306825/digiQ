import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_model.dart';

class BookingsStore extends Notifier<List<Booking>> {
  static const _storageKey = 'bookings';

  @override
  List<Booking> build() {
    _restoreBookings();
    return [];
  }

  /* --------------------------------------------------------------------------
   * Persistence helpers
   * -------------------------------------------------------------------------- */

  Future<void> _restoreBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;

    final List<dynamic> decoded = jsonDecode(jsonString);
    state = decoded
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persistBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((b) => b.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /* --------------------------------------------------------------------------
   * Public API (unchanged)
   * -------------------------------------------------------------------------- */

  void addBooking(Booking booking) {
    state = [...state, booking];
    _persistBookings();
  }

  void updateStatus(String bookingId, BookingStatus status) {
    state = [
      for (final booking in state)
        if (booking.id == bookingId)
          booking.copyWith(status: status)
        else
          booking,
    ];
    _persistBookings();
  }

  List<Booking> passengerBookings() {
    return state;
  }

  List<Booking> pendingDriverBookings() {
    return state.where((b) => b.status == BookingStatus.pending).toList();
  }
}

final bookingsStoreProvider = NotifierProvider<BookingsStore, List<Booking>>(
  BookingsStore.new,
);
