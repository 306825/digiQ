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

  Future<Response> getPendingVehicles() {
    return dio.get('/admin/vehicles/pending');
  }

  Future<Response> approveVehicle(String vehicleId) {
    return dio.patch('/admin/vehicles/$vehicleId/approve');
  }

  Future<Response> rejectVehicle(String vehicleId) {
    return dio.patch('/admin/vehicles/$vehicleId/reject');
  }

  Future<List<dynamic>> getActiveSos() async {
    final response = await dio.get('/admin/sos/active');
    return response.data;
  }

  Future<void> resolveSos(String id) async {
    await dio.patch('/admin/sos/$id/resolve');
  }
}

final adminSosProvider = FutureProvider((ref) async {
  final api = ref.read(adminApiProvider);
  return api.getActiveSos();
});

final adminApiProvider = Provider<AdminApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return AdminApi(dio);
});
