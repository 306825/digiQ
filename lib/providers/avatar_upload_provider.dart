import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/driver_documents_api.dart';
import '../core/api/user_api.dart';
import 'auth_provider.dart';

final avatarUploadProvider =
    FutureProvider.family<void, File>((ref, file) async {
  final userApi = ref.read(userApiProvider);
  final docsApi = ref.read(driverDocumentsApiProvider);
  final auth = ref.read(authProvider.notifier);

  final bytes = await file.readAsBytes();

  // 1. Get presigned upload URL from backend
  final uploadData = await userApi.getAvatarUploadUrl(
    contentType: 'image/jpeg',
  );

  final uploadUrl = uploadData['uploadUrl'] as String;
  final publicUrl = uploadData['publicUrl'] as String;

  // 2. Upload bytes to S3 via dart:io HttpClient (avoids Dio encoding issues)
  await docsApi.uploadToS3(
    uploadUrl: uploadUrl,
    bytes: bytes,
    contentType: 'image/jpeg',
  );

  debugPrint('[AVATAR] Upload complete, saving URL: $publicUrl');

  // 3. Save URL on backend
  final savedUrl = await userApi.saveAvatar(publicUrl);

  // 4. Refresh in-memory auth state
  await auth.updateAvatar(savedUrl);
});
