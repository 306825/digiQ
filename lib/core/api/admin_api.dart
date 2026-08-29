import 'package:digiQ/models/driver_model.dart';
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

  Future<List<Map<String, dynamic>>> getPendingPassengerVerifications() async {
    final res = await dio.get('/admin/passengers/pending-verification');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> approvePassengerVerification(String userId) async {
    await dio.patch('/admin/passengers/$userId/approve-verification');
  }

  Future<void> rejectPassengerVerification(String userId,
      {String? reason}) async {
    await dio.patch(
      '/admin/passengers/$userId/reject-verification',
      data: reason != null ? {'reason': reason} : null,
    );
  }

  /* --------------------------------------------------------------------------
   * PAYOUTS
   * -------------------------------------------------------------------------- */

  Future<List<Map<String, dynamic>>> getPendingPayouts() async {
    final res = await dio.get('/payouts/admin/pending');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> settleWithdrawal(String id, {String? adminNote}) async {
    await dio.patch('/payouts/admin/$id/settle',
        data: {'adminNote': adminNote});
  }

  Future<void> rejectWithdrawal(String id, {String? adminNote}) async {
    await dio.patch('/payouts/admin/$id/reject',
        data: {'adminNote': adminNote});
  }

  /* --------------------------------------------------------------------------
   * MANUAL PAYMENTS
   * -------------------------------------------------------------------------- */

  Future<List<Map<String, dynamic>>> getPendingManualPayments() async {
    final res = await dio.get('/payments/manual/pending');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> confirmManualPayment(String bookingId) async {
    await dio.post('/payments/manual/confirm/$bookingId');
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
