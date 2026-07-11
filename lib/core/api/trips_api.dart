import 'package:dio/dio.dart';
import '../../models/trip_model.dart';
import '../../models/trip_passenger_model.dart';

class TripsApi {
  final Dio dio;

  TripsApi(this.dio);

  Future<void> createTrip({
    required String routeId,
    required String departureWindow,
    required DateTime date,
    required String vehicleId,
    int minPassengers = 1,
  }) async {
    await dio.post(
      '/trips',
      data: {
        'routeId': routeId,
        'departureWindow': departureWindow,
        'date': date.toIso8601String(),
        'vehicleId': vehicleId,
        'minPassengers': minPassengers,
      },
    );
  }

  Future<void> startTrip(String tripId) async {
    await dio.patch('/trips/$tripId/start');
  }

  Future<void> completeTrip(String tripId) async {
    await dio.patch('/trips/$tripId/complete');
  }

  Future<Map<String, dynamic>> cancelTrip(String tripId) async {
    final response = await dio.patch('/trips/$tripId/cancel');
    return response.data as Map<String, dynamic>;
  }

  Future<void> sendSos(String bookingId) async {
    await dio.post('/trips/booking/$bookingId/sos');
  }

  Future<List<Trip>> getMyTrips() async {
    final response = await dio.get('/trips/mine');

    if (response.data is! List) {
      throw Exception('Invalid trips payload');
    }

    return (response.data as List)
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Trip>> searchTrips({
    required String routeId,
    required DateTime date,
  }) async {
    final response = await dio.get(
      '/trips/search',
      queryParameters: {
        'routeId': routeId,
        'date': date.toIso8601String(),
      },
    );

    if (response.data is! List) {
      throw Exception('Invalid search payload');
    }

    final list = response.data as List;

    return list
        .map((e) => Trip.fromSearchJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TripPassenger>> getTripPassengers(String tripId) async {
    final res = await dio.get('/trips/$tripId/passengers');
    return (res.data as List)
        .map((j) => TripPassenger.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> postLocation(String tripId, double lat, double lng) async {
    await dio.patch('/trips/$tripId/location', data: {'lat': lat, 'lng': lng});
  }

  /// Returns {lat, lng, updatedAt, status} or null lat/lng if never set.
  Future<Map<String, dynamic>?> getLocation(String tripId) async {
    final response = await dio.get('/trips/$tripId/location');
    return response.data as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> calculatePickupRoute(
    String tripId, {
    required double driverLat,
    required double driverLng,
  }) async {
    final response = await dio.post(
      '/trips/$tripId/pickup-route',
      data: {'driverLat': driverLat, 'driverLng': driverLng},
    );
    return response.data as Map<String, dynamic>;
  }
}
