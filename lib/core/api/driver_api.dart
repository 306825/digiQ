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

  // Future<void> submitBankDetails({
  //   required String bankName,
  //   required String accountName,
  //   required String accountNumber,
  //   required String branchCode,
  //   required String accountType,
  // }) async {
  //   await dio.post(
  //     '/drivers/verification/bank-details',
  //     data: {
  //       'bankName': bankName,
  //       'accountName': accountName,
  //       'accountNumber': accountNumber,
  //       'branchCode': branchCode,
  //       'accountType': accountType,
  //     },
  //   );
  // }

  Future<void> submitVerification({
    required String firstName,
    required String lastName,
    required String address,
    required String driversLicenseExpiry,
    required String prdpExpiry,

    // ✅ NEW — banking fields
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? branchCode,
    String? accountType,
    required Map<String, String> documents,
  }) async {
    final data = {
      'firstName': firstName,
      'lastName': lastName,
      'residentialAddress': address,
      'documents': documents,
      'driversLicenseExpiry': driversLicenseExpiry,
      'prdpExpiry': prdpExpiry
    };

// Only add banking fields if present
    if (bankName != null) data['bankName'] = bankName;
    if (accountName != null) data['accountName'] = accountName;
    if (accountNumber != null) data['accountNumber'] = accountNumber;
    if (branchCode != null) data['branchCode'] = branchCode;
    if (accountType != null) data['accountType'] = accountType;

    await dio.post('/drivers/verification/submit', data: data);
  }

  /* --------------------------------------------------------------------------
   * DRIVER BALANCE
   * -------------------------------------------------------------------------- */

  Future<DriverBalance> getBalance() async {
    final res = await dio.get('/drivers/me/balance');
    return DriverBalance.fromJson(res.data);
  }

  /* --------------------------------------------------------------------------
   * PAYOUTS / WITHDRAWALS
   * -------------------------------------------------------------------------- */

  Future<void> requestWithdrawal(double amount) async {
    await dio.post('/payouts/withdrawal', data: {'amount': amount});
  }

  Future<void> updateBankDetails({
    required String bankName,
    required String accountName,
    required String accountNumber,
    String? branchCode,
    required String accountType,
  }) async {
    await dio.patch('/drivers/me/bank-details', data: {
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'branchCode': branchCode ?? '',
      'accountType': accountType,
    });
  }

  Future<List<WithdrawalRequest>> getPayoutHistory() async {
    final res = await dio.get('/payouts/history');
    return (res.data as List)
        .map((j) => WithdrawalRequest.fromJson(j))
        .toList();
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

  Future<void> submitVehicle({
    required String registrationNumber,
    String? make,
    String? model,
    int? year,
    required String roadworthyDocUrl,
    required String operatingLicenseDocUrl,
    required String roadworthyExpiry,
    required String operatingLicenseExpiry,
  }) async {
    await dio.post(
      '/drivers/vehicle/submit',
      data: {
        'registrationNumber': registrationNumber,
        'make': make,
        'model': model,
        'year': year,
        'roadworthyDocUrl': roadworthyDocUrl,
        'operatingLicenseDocUrl': operatingLicenseDocUrl,
        'roadworthyExpiry': roadworthyExpiry,
        'operatingLicenseExpiry': operatingLicenseExpiry,
      },
    );
  }

  // Future<Map<String, dynamic>?> getMyVehicle() async {
  //   final res = await dio.get('/drivers/me/vehicle');
  //   return res.data;
  // }

  Future<Map<String, dynamic>?> getMyVehicle() async {
    final res = await dio.get('/drivers/me/vehicle');

    final data = res.data;

    // ✅ Handle null / empty response
    if (data == null || data == '') {
      return null;
    }

    // ✅ Ensure correct type
    if (data is Map<String, dynamic>) {
      return data;
    }

    // ❌ Unexpected type (log it)
    print("⚠️ Unexpected vehicle response: $data");

    return null;
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
