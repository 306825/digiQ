import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/models/trip_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverTripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    try {
      final trips = await ref.read(tripsApiProvider).getMyTrips();
      return _sorted(trips);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        rethrow;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final driverTripsProvider =
    AsyncNotifierProvider<DriverTripsNotifier, List<Trip>>(
  DriverTripsNotifier.new,
);

/* --------------------------------------------------------------------------
 * Sort: active → scheduled (soonest first) → completed/cancelled (newest first)
 * -------------------------------------------------------------------------- */

List<Trip> _sorted(List<Trip> trips) {
  final result = [...trips];
  result.sort((a, b) {
    final pa = _priority(a.status);
    final pb = _priority(b.status);
    if (pa != pb) return pa.compareTo(pb);

    // Past trips (completed / cancelled): most recent at top.
    final descending = pa == 2;
    final dateCmp = a.date.compareTo(b.date);
    if (dateCmp != 0) return descending ? -dateCmp : dateCmp;

    // Same date: earlier departure window first.
    return _windowOrder(a.departureWindow)
        .compareTo(_windowOrder(b.departureWindow));
  });
  return result;
}

int _priority(String status) {
  switch (status) {
    case 'active':    return 0;
    case 'scheduled': return 1;
    default:          return 2; // completed, cancelled
  }
}

int _windowOrder(String window) {
  switch (window) {
    case '08-10': return 0;
    case '11-13': return 1;
    case '14-16': return 2;
    default:      return 3;
  }
}
