import 'dart:io';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/avatar_upload_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends ConsumerWidget {
  const AvatarPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 75,
        );

        if (picked == null) return;

        // ✅ ONLY call provider when File exists
        await ref.read(
          avatarUploadProvider(File(picked.path)).future,
        );
      },
      child: CircleAvatar(
        radius: 36,
        backgroundImage: user?.profileImageUrl != null
            ? NetworkImage(user!.profileImageUrl!)
            : null,
        child: user?.profileImageUrl == null
            ? const Icon(Icons.person, size: 36)
            : null,
      ),
    );
  }
}
