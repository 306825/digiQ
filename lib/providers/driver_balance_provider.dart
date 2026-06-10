import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/models/driver_model.dart';

// final driverBalanceProvider = FutureProvider<DriverBalance>((ref) async {
//   final driverApi = ref.read(driverApiProvider);
//   print("🔥 CALLING DRIVER BALANCE API");
//   return driverApi.getBalance();
// });

final driverBalanceProvider = FutureProvider<DriverBalance>((ref) async {
  final auth = ref.watch(authProvider);

  // 🚫 Block until authenticated
  if (!auth.isAuthenticated || auth.token == null) {
    throw Exception("Not authenticated yet");
  }

  final driverApi = ref.read(driverApiProvider);

  print("🔥 CALLING DRIVER BALANCE API WITH TOKEN: ${auth.token}");

  return driverApi.getBalance();
});
