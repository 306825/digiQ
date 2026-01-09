import 'package:digiQ/models/trip_model.dart';
import 'package:digiQ/models/trip_search_params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripSearchNotifier extends Notifier<AsyncValue<List<Trip>>> {
  @override
  AsyncValue<List<Trip>> build() {
    return const AsyncValue.loading();
  }

  Future<void> search(TripSearchParams params) async {
    state = const AsyncValue.loading();

    // TEMP MOCK DATA — matches Trip model exactly
    state = AsyncValue.data([
      Trip(
        id: 'mock-trip-1',
        driverId: 'mock-driver-1',
        driverName: 'Thabo',
        from: params.from,
        to: params.to,
        date: params.date,
        seatsTotal: 3,
        seatsAvailable: 2,
        price: 250.0,
        status: 'open',
      ),
    ]);
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

final tripSearchProvider =
    NotifierProvider<TripSearchNotifier, AsyncValue<List<Trip>>>(
  TripSearchNotifier.new,
);
