import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/models/trip_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverTripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    try {
      final trips = await ref.read(tripsApiProvider).getMyTrips();
      return trips;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        ref.read(authProvider.notifier).refreshMe();
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    // 🔄 Proper Riverpod refresh
    ref.invalidateSelf();
    await future;
  }
}

final driverTripsProvider =
    AsyncNotifierProvider<DriverTripsNotifier, List<Trip>>(
  DriverTripsNotifier.new,
);
