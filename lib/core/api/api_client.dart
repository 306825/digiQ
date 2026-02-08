import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            //baseUrl: 'http://localhost:3000/api/v1',
            baseUrl:
                'https://nonembryonal-terese-unveritable.ngrok-free.dev/api/v1',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ) {
    print('🔥 API BASE URL = ${dio.options.baseUrl}');
  }
}
