import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

class AdminApi {
  final Dio dio;

  AdminApi(this.dio);

  Future<Response> getPendingDrivers() {
    return dio.get('/admin/drivers/pending');
  }

  Future<Response> approveDriver(String userId) {
    return dio.patch('/admin/drivers/$userId/approve');
  }

  Future<Response> rejectDriver(String userId) {
    return dio.patch('/admin/drivers/$userId/reject');
  }

  Future<Response> getDrivers() {
    print('👮 ADMIN → fetching ALL drivers');
    return dio.get('/admin/drivers');
  }

  Future<void> deactivateDriver(String driverId) async {
    await dio.post('/admin/drivers/$driverId/deactivate');
  }

  Future<void> activateDriver(String driverId) async {
    await dio.post('/admin/drivers/$driverId/activate');
  }
}

final adminApiProvider = Provider<AdminApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return AdminApi(dio);
});
