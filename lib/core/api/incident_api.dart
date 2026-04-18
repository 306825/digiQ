import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiQ/core/api/api_providers.dart';

class IncidentApi {
  final Dio dio;

  IncidentApi(this.dio);

  Future<void> reportIncident({
    required String bookingId,
    required String type,
    String? description,
  }) async {
    await dio.post(
      '/incidents',
      data: {
        'bookingId': bookingId,
        'type': type,
        'description': description,
      },
    );
  }

  Future<Map<String, dynamic>?> getIncidentByBooking(String bookingId) async {
    final res = await dio.get('/incidents/booking/$bookingId');
    return res.data;
  }

  Future<List<dynamic>> getAllIncidents() async {
    final res = await dio.get('/incidents');
    return res.data;
  }

  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
  }) async {
    await dio.patch(
      '/incidents/$incidentId/status',
      data: {'status': status},
    );
  }
}

final incidentApiProvider = Provider<IncidentApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return IncidentApi(dio);
});
