import 'package:digiQ/core/api/admin_api.dart';
import 'package:digiQ/core/api/driver_api.dart';
import 'package:digiQ/core/api/payments_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'trips_api.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final tripsApiProvider = Provider<TripsApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return TripsApi(dio);
});

final driverApiProvider = Provider<DriverApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return DriverApi(dio);
});

final adminApiProvider = Provider<AdminApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return AdminApi(dio);
});

final paymentsApiProvider = Provider<PaymentsApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return PaymentsApi(dio);
});
