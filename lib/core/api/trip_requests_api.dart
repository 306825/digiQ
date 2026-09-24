import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/models/trip_request_model.dart';
import 'api_providers.dart';

class TripRequestsApi {
  final Dio _dio;
  TripRequestsApi(this._dio);

  Future<TripRequestModel> create({
    required String routeId,
    required String from,
    required String to,
    required String date,
    required int seatsNeeded,
    required DepositMethod depositMethod,
  }) async {
    final res = await _dio.post('/trip-requests', data: {
      'routeId': routeId,
      'from': from,
      'to': to,
      'date': date,
      'seatsNeeded': seatsNeeded,
      'depositMethod': depositMethod == DepositMethod.payshap ? 'payshap' : 'eft',
    });
    return TripRequestModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TripRequestModel>> mine() async {
    final res = await _dio.get('/trip-requests/mine');
    final list = res.data as List;
    return list.map((e) => TripRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TripRequestModel> markDepositSent(String id) async {
    final res = await _dio.patch('/trip-requests/$id/deposit-sent');
    return TripRequestModel.fromJson(res.data as Map<String, dynamic>);
  }

  // Admin
  Future<List<TripRequestModel>> adminList() async {
    final res = await _dio.get('/admin/trip-requests');
    final list = res.data as List;
    return list.map((e) => TripRequestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TripRequestModel> adminConfirmDeposit(String id) async {
    final res = await _dio.patch('/admin/trip-requests/$id/confirm-deposit');
    return TripRequestModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TripRequestModel> adminLinkTrip(String id, String tripId) async {
    final res = await _dio.patch(
      '/admin/trip-requests/$id/link-trip',
      data: {'tripId': tripId},
    );
    return TripRequestModel.fromJson(res.data as Map<String, dynamic>);
  }
}

final tripRequestsApiProvider = Provider<TripRequestsApi>((ref) {
  return TripRequestsApi(ref.read(apiClientProvider).dio);
});
