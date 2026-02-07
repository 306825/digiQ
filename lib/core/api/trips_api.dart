import 'package:dio/dio.dart';
import '../../models/trip_model.dart';

class TripsApi {
  final Dio dio;

  TripsApi(this.dio);

  Future<void> createTrip({
    required String routeId,
    required String departureWindow,
    required DateTime date,
    required int seatsTotal,
    required double price,
  }) async {
    await dio.post(
      '/trips',
      data: {
        'routeId': routeId,
        'departureWindow': departureWindow,
        'date': date.toIso8601String(),
        'seatsTotal': seatsTotal,
        'price': price,
      },
    );
  }

  Future<List<Trip>> getMyTrips() async {
    final response = await dio.get('/trips/mine');

    if (response.data is! List) {
      throw Exception('Invalid trips payload');
    }

    final list = response.data as List;

    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
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
}
