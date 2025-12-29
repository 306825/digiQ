import 'package:digiQ/models/trip_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverTripsProvider = FutureProvider<List<Trip>>((ref) async {
  // API call
  return [];
});
