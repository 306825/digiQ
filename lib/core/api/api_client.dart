// import 'package:dio/dio.dart';

// class ApiClient {
//   final Dio dio;

//   ApiClient()
//       : dio = Dio(
//           BaseOptions(
//             //baseUrl: 'http://localhost:3000/api/v1',
//             baseUrl:
//                 'https://nonembryonal-terese-unveritable.ngrok-free.dev/api/v1',
//             connectTimeout: const Duration(seconds: 10),
//             receiveTimeout: const Duration(seconds: 10),
//             headers: {
//               'Content-Type': 'application/json',
//             },
//           ),
//         ) {

//     print('🔥 API BASE URL = ${dio.options.baseUrl}');
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  static const _storage = FlutterSecureStorage();

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.digiqueue.co.za/api/v1',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
      ),
    );
  }
}

final apiClient = ApiClient();
