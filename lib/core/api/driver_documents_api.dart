import 'dart:io';

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

  /// Upload file bytes directly to S3 via a presigned PUT URL.
  ///
  /// Uses dart:io HttpClient so that:
  ///   1. The raw bytes are written without any Dio encoding transforms.
  ///   2. A non-2xx status (e.g. S3 403 SignatureDoesNotMatch) throws and
  ///      surfaces the real error instead of being silently swallowed.
  Future<void> uploadToS3({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.putUrl(Uri.parse(uploadUrl));
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('S3 upload failed (HTTP ${response.statusCode})');
      }
    } finally {
      client.close();
    }
  }
}
