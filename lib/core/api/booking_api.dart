import 'package:digiQ/core/api/api_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingApi {
  final Dio dio;

  BookingApi(this.dio);

  Future<void> respondToBooking({
    required String bookingId,
    required String status, // approved | rejected
  }) async {
    await dio.post(
      '/bookings/$bookingId/respond',
      data: {'status': status},
    );
  }
}

final bookingApiProvider = Provider<BookingApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return BookingApi(dio);
});
