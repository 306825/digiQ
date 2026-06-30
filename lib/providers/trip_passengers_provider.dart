import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_providers.dart';
import '../models/trip_passenger_model.dart';

final tripPassengersProvider = FutureProvider.family<List<TripPassenger>, String>(
  (ref, tripId) => ref.read(tripsApiProvider).getTripPassengers(tripId),
);
