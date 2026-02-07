import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

final driverDocumentsApiProvider = Provider<DriverDocumentsApi>((ref) {
  final dio = ref.read(apiClientProvider).dio;
  return DriverDocumentsApi(dio);
});

class DriverDocumentsApi {
  final Dio dio;
  DriverDocumentsApi(this.dio);

  /// Ask backend for signed upload URL
  Future<Map<String, dynamic>> getUploadUrl({
    required String type,
    required String contentType,
  }) async {
    final response = await dio.post(
      '/drivers/upload-url',
      data: {
        'type': type,
        'contentType': contentType,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  /// Upload file directly to S3
  Future<void> uploadToS3({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    final s3 = Dio();

    try {
      final response = await s3.put(
        uploadUrl,
        data: Uint8List.fromList(bytes), // ✅ NOT a Stream
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length, // ✅ Important
          },
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('✅ S3 upload status: ${response.statusCode}');
    } catch (e) {
      print('❌ S3 upload failed: $e');
      rethrow;
    }
  }
}
