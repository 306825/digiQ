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

  // Registered by AuthNotifier to handle forced logout on 401
  static void Function()? onUnauthorized;

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
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token is invalid/expired — clear credentials and force re-login
            await _storage.delete(key: 'auth_token');
            await _storage.delete(key: 'auth_user');
            ApiClient.onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }
}

final apiClient = ApiClient();
