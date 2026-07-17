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
    int seatsBooked = 1,
  }) {
    return dio.post(
      '/bookings',
      data: {
        'tripId': tripId,
        'pickup': pickup,
        'seatsBooked': seatsBooked,
      },
    );
  }

  /* --------------------------------------------------------------------------
   * MY BOOKINGS (Passenger)
   * -------------------------------------------------------------------------- */
  Future<Response> getMyBookings() {
    return dio.get('/bookings/mine');
  }

  Future<void> confirmPickup(String bookingId) async {
    await dio.patch('/bookings/$bookingId/confirm-pickup');
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

  Future<void> rateDriver({
    required String bookingId,
    required int stars,
    String? comment,
  }) async {
    await dio.post('/ratings', data: {
      'bookingId': bookingId,
      'stars': stars,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }
}

final bookingApiProvider = Provider<BookingApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return BookingApi(dio);
});
