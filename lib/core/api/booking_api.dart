import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiQ/core/api/api_providers.dart';

class BookingApi {
  final Dio dio;

  BookingApi(this.dio);

  /* --------------------------------------------------------------------------
   * CREATE BOOKING (Passenger)
   * -------------------------------------------------------------------------- */
  Future<Response> createBooking({
    required String tripId,
    required Map<String, dynamic> pickup,
  }) {
    return dio.post(
      '/bookings',
      data: {
        'tripId': tripId,
        'pickup': pickup,
      },
    );
  }

  /* --------------------------------------------------------------------------
   * MY BOOKINGS (Passenger)
   * -------------------------------------------------------------------------- */
  Future<Response> getMyBookings() {
    return dio.get('/bookings/mine');
  }

  /* --------------------------------------------------------------------------
   * PENDING BOOKINGS (Driver)
   * -------------------------------------------------------------------------- */
  Future<Response> getPendingBookings() {
    return dio.get('/bookings/pending');
  }

  /* --------------------------------------------------------------------------
   * RESPOND TO BOOKING (Driver)
   * -------------------------------------------------------------------------- */
  Future<Response> updateBookingStatus({
    required String bookingId,
    required String status, // approved | rejected
  }) {
    return dio.patch(
      '/bookings/$bookingId',
      data: {'status': status},
    );
  }

  /* --------------------------------------------------------------------------
 * CANCEL BOOKING (Passenger)
 * -------------------------------------------------------------------------- */
  Future<Response> cancelBooking(String bookingId) {
    return dio.patch('/bookings/$bookingId/cancel');
  }
}

final bookingApiProvider = Provider<BookingApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return BookingApi(dio);
});
