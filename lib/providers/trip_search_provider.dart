import 'package:digiQ/models/trip_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class TripSearchNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  TripSearchNotifier() : super(const AsyncValue.loading());

  Future<void> search(TripSearchParams params) async {
    state = const AsyncValue.loading();

    // API call here

    state = AsyncValue.data([
      Trip(id: "1", driverName: "Thabo", rating: 4.6, price: 250, seatsLeft: 2),
    ]);
  }
}

final tripSearchProvider =
    StateNotifierProvider<TripSearchNotifier, AsyncValue<List<Trip>>>(
      (ref) => TripSearchNotifier(),
    );
