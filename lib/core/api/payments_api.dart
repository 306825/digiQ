// core/api/payments_api.dart

import 'package:dio/dio.dart';

class PaymentsApi {
  final Dio dio;
  PaymentsApi(this.dio);

  Future<Map<String, dynamic>> initiatePayfast({
    required String bookingId,
  }) async {
    print('🔥 PAYMENTS API CALLED WITH bookingId=$bookingId');

    try {
      final res = await dio.post(
        '/payments/payfast/initiate',
        data: {'bookingId': bookingId},
      );

      print('✅ PAYFAST INIT RESPONSE STATUS = ${res.statusCode}');
      print('✅ PAYFAST INIT RESPONSE BODY = ${res.data}');

      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ PAYFAST INIT ERROR STATUS = ${e.response?.statusCode}');
      print('❌ PAYFAST INIT ERROR BODY = ${e.response?.data}');
      rethrow;
    }
  }
}
