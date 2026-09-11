import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/models/trip_model.dart';
import 'package:strut/providers/driver_trips_provider.dart';

/// Cumulative, read-only earnings for the signed-in driver.
///
/// This is *not* a withdrawable balance. Passengers pay the driver directly by
/// PayShap or EFT, so Strut never holds these funds — the figure exists so the
/// driver can see what they have earned to date, and so we retain a record of
/// volume while the payment gateway is unavailable.
class DriverEarnings {
  /// Sum of seats sold × net price per seat, over completed trips only.
  final double totalEarned;

  final int tripsCompleted;
  final int seatsSold;

  const DriverEarnings({
    required this.totalEarned,
    required this.tripsCompleted,
    required this.seatsSold,
  });

  static const empty =
      DriverEarnings(totalEarned: 0, tripsCompleted: 0, seatsSold: 0);
}

/// Derived from [driverTripsProvider] rather than a dedicated endpoint, so it
/// reuses trips the dashboard has already loaded and needs no extra request.
///
/// Seats sold per trip is `seatsTotal - seatsAvailable`. Note this is only
/// exact once the backend defers the seat decrement to driver approval; until
/// then a trip that had bookings requested but never approved will read
/// slightly high.
final driverEarningsProvider = Provider<AsyncValue<DriverEarnings>>((ref) {
  return ref.watch(driverTripsProvider).whenData(_summarise);
});

DriverEarnings _summarise(List<Trip> trips) {
  var totalEarned = 0.0;
  var tripsCompleted = 0;
  var seatsSold = 0;

  for (final trip in trips) {
    if (trip.status != 'completed') continue;

    tripsCompleted++;

    final sold = (trip.seatsTotal - trip.seatsAvailable).clamp(0, trip.seatsTotal);
    seatsSold += sold;
    totalEarned += sold * (trip.netPricePerSeat ?? trip.price);
  }

  return DriverEarnings(
    totalEarned: totalEarned,
    tripsCompleted: tripsCompleted,
    seatsSold: seatsSold,
  );
}
