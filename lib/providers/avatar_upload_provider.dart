import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/user_api.dart';
import 'auth_provider.dart';

final avatarUploadProvider =
    FutureProvider.family<void, File>((ref, file) async {
  final userApi = ref.read(userApiProvider);
  final auth = ref.read(authProvider.notifier);

  final contentType = 'image/${file.path.split('.').last}';

  // 1️⃣ Get signed URL
  final uploadData = await userApi.getAvatarUploadUrl(
    contentType: contentType,
  );

  final uploadUrl = uploadData['uploadUrl'] as String;
  final key = uploadData['key'] as String;

  // 2️⃣ Upload to S3
  await Dio().put(
    uploadUrl,
    data: await file.readAsBytes(),
    options: Options(
      headers: {
        'Content-Type': contentType,
      },
    ),
  );

  // 3️⃣ Build public URL (same logic as backend)
  final publicUrl = 'https://digiq-documents.s3.af-south-1.amazonaws.com/$key';

  // 4️⃣ Save on backend
  await userApi.saveAvatar(publicUrl);

  // 5️⃣ Refresh auth user
  await auth.updateAvatar(publicUrl);
});
