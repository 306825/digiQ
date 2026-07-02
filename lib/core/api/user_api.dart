import 'package:digiQ/core/api/api_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserApi {
  final Dio dio;
  UserApi(this.dio);

  Future<Map<String, dynamic>> getAvatarUploadUrl({
    required String contentType,
  }) async {
    final res = await dio.post(
      '/users/me/avatar/upload-url',
      data: {'contentType': contentType},
    );
    return res.data;
  }

  Future<String> saveAvatar(String profileImageUrl) async {
    final res = await dio.patch(
      '/users/me/avatar',
      data: {'profileImageUrl': profileImageUrl},
    );
    return res.data['profileImageUrl'];
  }

  Future<void> registerFcmToken(String token) async {
    await dio.post('/users/fcm-token', data: {'token': token});
  }

  Future<void> removeFcmToken(String token) async {
    await dio.delete('/users/fcm-token', data: {'token': token});
  }
}

final userApiProvider = Provider<UserApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return UserApi(dio);
});
