import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart'; // where apiClientProvider lives

final tripsApiProvider = Provider<TripsApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return TripsApi(dio);
});

class TripsApi {
  final Dio dio;

  TripsApi(this.dio);

  Future<Response> createTrip({
    required String from,
    required String to,
    required DateTime date,
    required int seatsTotal,
    required double price,
  }) {
    return dio.post(
      '/trips',
      data: {
        'from': from,
        'to': to,
        'date': date.toIso8601String(),
        'seatsTotal': seatsTotal,
        'price': price,
      },
    );
  }

  Future<Response> getMyTrips() {
    return dio.get('/trips/mine');
  }
}
