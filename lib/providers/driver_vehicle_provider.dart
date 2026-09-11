import 'package:strut/models/vehicle_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/core/api/api_providers.dart';

final driverVehicleProvider =
    FutureProvider<List<VehicleModel>>((ref) async {
  final api = ref.read(driverApiProvider);
  return api.getMyVehicles();
});
