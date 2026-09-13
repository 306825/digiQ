import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

class AdminRoutesApi {
  final Dio dio;
  AdminRoutesApi(this.dio);

  Future<Response> getRoutes() {
    return dio.get('/admin/routes');
  }

  Future<Response> createRoute({
    required String from,
    required String to,
    required List<Map<String, dynamic>> dropoffs,
  }) {
    return dio.post(
      '/admin/routes',
      data: {
        'from': from,
        'to': to,
        'dropoffs': dropoffs,
      },
    );
  }

  Future<Response> updateRouteDropoffs({
    required String routeId,
    required List<Map<String, dynamic>> dropoffs,
  }) {
    return dio.patch(
      '/admin/routes/$routeId',
      data: {'dropoffs': dropoffs},
    );
  }

  Future<Response> toggleRouteActive({
    required String routeId,
    required bool isActive,
  }) {
    return dio.patch(
      '/admin/routes/$routeId',
      data: {'isActive': isActive},
    );
  }
}

final adminRoutesApiProvider = Provider<AdminRoutesApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return AdminRoutesApi(dio);
});
