import 'package:digiQ/models/trip_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripSearchNotifier extends Notifier<AsyncValue<List<Trip>>> {
  @override
  AsyncValue<List<Trip>> build() {
    return const AsyncValue.loading();
  }

  Future<void> search(TripSearchParams params) async {
    state = const AsyncValue.loading();

    state = AsyncValue.data([
      Trip(
        id: "1",
        driverName: "Thabo",
        rating: 4.6,
        price: 250,
        seatsLeft: 2,
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
