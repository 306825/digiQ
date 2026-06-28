import 'package:digiQ/models/vehicle_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiQ/core/api/api_providers.dart';

final driverVehicleProvider =
    FutureProvider<List<VehicleModel>>((ref) async {
  final api = ref.read(driverApiProvider);
  return api.getMyVehicles();
});
