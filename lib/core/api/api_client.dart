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
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ApiClient {
  final Dio dio;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl:
                'https://nonembryonal-terese-unveritable.ngrok-free.dev/api/v1',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            print("TOKEN HEADER = Bearer $token");
          }
          return handler.next(options);
        },
      ),
    );
  }
}
