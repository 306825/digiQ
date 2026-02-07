import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

class RoutesApi {
  final Dio dio;
  RoutesApi(this.dio);

  Future<Response> getRoutes() {
    return dio.get('/routes');
  }
}

final routesApiProvider = Provider<RoutesApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return RoutesApi(dio);
});
