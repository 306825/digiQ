import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/models/driver_follow_model.dart';
import 'api_providers.dart';


class DriverFollowsApi {
  final Dio _dio;
  DriverFollowsApi(this._dio);

  Future<DriverCard?> searchDriver(String q) async {
    final res = await _dio.get('/drivers/search', queryParameters: {'q': q});
    final data = res.data as Map<String, dynamic>;
    if (data['driver'] == null) return null;
    return DriverCard.fromJson(data['driver'] as Map<String, dynamic>);
  }

  Future<DriverPublicProfile> publicProfile(String driverId) async {
    final res = await _dio.get('/drivers/$driverId/public-profile');
    return DriverPublicProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> follow(String driverId) async {
    await _dio.post('/drivers/$driverId/follow');
  }

  Future<void> unfollow(String driverId) async {
    await _dio.delete('/drivers/$driverId/follow');
  }

  Future<List<DriverCard>> myFollowing() async {
    final res = await _dio.get('/passengers/me/following');
    final list = res.data as List;
    return list.map((e) => DriverCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DriverUpcomingTrip>> upcomingTrips(String driverId) async {
    final res = await _dio.get('/drivers/$driverId/upcoming-trips');
    final list = res.data as List;
    return list.map((e) => DriverUpcomingTrip.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final driverFollowsApiProvider = Provider<DriverFollowsApi>((ref) {
  return DriverFollowsApi(ref.read(apiClientProvider).dio);
});
