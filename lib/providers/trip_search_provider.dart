import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_providers.dart';
import '../models/trip_model.dart';
import '../models/trip_search_params.dart';

class TripSearchNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() {
    // Never resolves — keeps the provider in AsyncLoading until search()
    // explicitly sets the state. Prevents the empty-state flash on first render.
    return Completer<List<Trip>>().future;
  }

  Future<void> search(TripSearchParams params) async {
    state = const AsyncLoading();

    try {
      final api = ref.read(tripsApiProvider);

      final trips = await api.searchTrips(
        routeId: params.routeId,
        date: params.date,
      );

      state = AsyncData(trips);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  void reset() {
    state = const AsyncData([]);
  }
}

final tripSearchProvider =
    AsyncNotifierProvider<TripSearchNotifier, List<Trip>>(
  TripSearchNotifier.new,
);
