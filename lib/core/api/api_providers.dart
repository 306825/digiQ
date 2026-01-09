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
