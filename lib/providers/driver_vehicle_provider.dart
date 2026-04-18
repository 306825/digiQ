import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiQ/core/api/api_providers.dart';

final driverVehicleProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.read(driverApiProvider);
  return api.getMyVehicle();
});
