import 'package:flutter_riverpod/legacy.dart';
import '../models/booking_entity.dart';

class BookingsStore extends StateNotifier<List<BookingEntity>> {
  BookingsStore() : super([]);

  void addBooking(BookingEntity booking) {
    state = [...state, booking];
  }

  void updateStatus(String bookingId, BookingStatus status) {
    state = state.map((b) {
      if (b.id == bookingId) {
        return b.copyWith(status: status);
      }
      return b;
    }).toList();
  }

  List<BookingEntity> passengerBookings() {
    return state;
  }

  List<BookingEntity> pendingDriverBookings() {
    return state.where((b) => b.status == BookingStatus.pending).toList();
  }
}

final bookingsStoreProvider =
    StateNotifierProvider<BookingsStore, List<BookingEntity>>(
      (ref) => BookingsStore(),
    );
