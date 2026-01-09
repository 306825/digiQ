import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/models/trip_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverTripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    final api = ref.read(tripsApiProvider);
    final response = await api.getMyTrips();

    final List<dynamic> list = response.data;
    return list.map((e) => Trip.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final driverTripsProvider =
    AsyncNotifierProvider<DriverTripsNotifier, List<Trip>>(
  DriverTripsNotifier.new,
);
