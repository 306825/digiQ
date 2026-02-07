import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/models/driver_model.dart';
import 'package:digiQ/models/driver_booking_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverApi {
  final Dio dio;
  DriverApi(this.dio);

  /* --------------------------------------------------------------------------
   * DRIVER VERIFICATION
   * -------------------------------------------------------------------------- */

  Future<void> requestVerification() async {
    await dio.post('/drivers/verification/request');
  }

  Future<void> submitVerification({
    required String firstName,
    required String lastName,
    required String address,
    required Map<String, String> documents,
  }) async {
    await dio.post(
      '/drivers/verification/submit',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'residentialAddress': address,
        'documents': documents,
      },
    );
  }

  /* --------------------------------------------------------------------------
   * DRIVER BALANCE
   * -------------------------------------------------------------------------- */

  Future<DriverBalance> getBalance() async {
    final res = await dio.get('/drivers/me/balance');
    return DriverBalance.fromJson(res.data);
  }

  /* --------------------------------------------------------------------------
   * DRIVER BOOKINGS
   * -------------------------------------------------------------------------- */

  /// Fetch paid, pending bookings for this driver
  Future<List<DriverBooking>> getPendingBookings() async {
    final res = await dio.get('/bookings/pending');

    return (res.data as List)
        .map((json) => DriverBooking.fromJson(json))
        .toList();
  }

  /// Approve or reject a booking
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status, // 'approved' | 'rejected'
  }) async {
    await dio.patch(
      '/bookings/$bookingId',
      data: {'status': status},
    );
  }
}

/// ✅ PROVIDER MUST LIVE OUTSIDE THE CLASS
final driverApiProvider = Provider<DriverApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return DriverApi(dio);
});
