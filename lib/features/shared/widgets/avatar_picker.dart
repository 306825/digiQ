import 'dart:io';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/avatar_upload_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class AvatarPicker extends ConsumerStatefulWidget {
  const AvatarPicker({super.key});

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  bool _uploading = false;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await ref.read(avatarUploadProvider(File(picked.path)).future);
    } catch (e, st) {
      debugPrint('[AVATAR] Upload failed: $e');
      debugPrint('[AVATAR] $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return GestureDetector(
      onTap: _uploading ? null : _pick,
      child: CircleAvatar(
        radius: 36,
        backgroundImage: user?.profileImageUrl != null
            ? NetworkImage(user!.profileImageUrl!)
            : null,
        child: _uploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : user?.profileImageUrl == null
                ? const Icon(Icons.person, size: 36)
                : null,
      ),
    );
  }
}
