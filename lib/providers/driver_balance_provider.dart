import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/models/driver_model.dart';

final driverBalanceProvider = FutureProvider<DriverBalance>((ref) async {
  final driverApi = ref.read(driverApiProvider);
  return driverApi.getBalance();
});
