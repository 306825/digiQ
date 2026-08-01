import 'package:dio/dio.dart';

class PaymentsApi {
  final Dio dio;
  PaymentsApi(this.dio);

  Future<Map<String, dynamic>> initiatePayfast({
    required String bookingId,
  }) async {
    final res = await dio.post(
      '/payments/payfast/initiate',
      data: {'bookingId': bookingId},
    );
    return res.data as Map<String, dynamic>;
  }
}
