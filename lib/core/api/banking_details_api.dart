import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/models/banking_details_model.dart';
import 'api_providers.dart';

class BankingDetailsApi {
  final Dio _dio;
  BankingDetailsApi(this._dio);

  Future<BankingDetails> adminGet() async {
    final res = await _dio.get('/admin/banking-details');
    return BankingDetails.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BankingDetails> adminUpdate(BankingDetails details) async {
    final res = await _dio.put(
      '/admin/banking-details',
      data: details.toJson(),
    );
    return BankingDetails.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BankingDetails> passengerGet() async {
    final res = await _dio.get('/banking-details');
    return BankingDetails.fromJson(res.data as Map<String, dynamic>);
  }
}

final bankingDetailsApiProvider = Provider<BankingDetailsApi>((ref) {
  return BankingDetailsApi(ref.read(apiClientProvider).dio);
});
