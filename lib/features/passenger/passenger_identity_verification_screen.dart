import 'dart:io';

import 'package:digiQ/core/api/driver_documents_api.dart';
import 'package:digiQ/core/api/user_api.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class PassengerIdentityVerificationScreen extends ConsumerStatefulWidget {
  const PassengerIdentityVerificationScreen({super.key});

  @override
  ConsumerState<PassengerIdentityVerificationScreen> createState() =>
      _PassengerIdentityVerificationScreenState();
}

class _PassengerIdentityVerificationScreenState
    extends ConsumerState<PassengerIdentityVerificationScreen> {
  File? _selfie;
  bool _uploading = false;
  bool _submitted = false;
  String? _error;

  Future<void> _pickSelfie(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selfie = File(picked.path);
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_selfie == null) {
      setState(() => _error = 'Please take or choose a photo first.');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final userApi = ref.read(userApiProvider);
      final docsApi = ref.read(driverDocumentsApiProvider);

      // 1. Get presigned PUT URL
      final uploadData = await userApi.getPassengerVerificationUploadUrl();
      final uploadUrl = uploadData['uploadUrl'] as String;
      final s3Key = uploadData['key'] as String;

      // 2. Upload bytes via dart:io (avoids Dio encoding issues)
      final bytes = await _selfie!.readAsBytes();
      await docsApi.uploadToS3(
        uploadUrl: uploadUrl,
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      // 3. Submit selfie S3 key to backend
      await userApi.submitPassengerVerification(s3Key);

      // 4. Persist updated status to memory and secure storage
      await ref
          .read(authProvider.notifier)
          .updatePassengerVerificationStatus(PassengerVerificationStatus.pending);

      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;

      // Backend rejects re-submission for already-approved passengers.
      // Refresh the local status so the profile screen reflects it.
      final isAlreadyVerified = e is DioException &&
          e.response?.statusCode == 400 &&
          (e.response?.data?['message'] ?? '')
              .toString()
              .toLowerCase()
              .contains('already verified');

      if (isAlreadyVerified) {
        await ref.read(authProvider.notifier).refreshMe();
        if (mounted) Navigator.of(context).pop();
        return;
      }

      setState(() {
        _error = 'Upload failed. Please try again.';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Identity'),
        centerTitle: true,
      ),
      body: _submitted ? _SuccessView() : _FormView(this),
    );
  }
}

/* --------------------------------------------------------------------------
 * Form view
 * -------------------------------------------------------------------------- */

class _FormView extends StatelessWidget {
  final _PassengerIdentityVerificationScreenState state;

  const _FormView(this.state);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...[
                  'Take a clear selfie of yourself holding your government-issued ID (ID card, passport, or driver\'s licence).',
                  'Make sure your face and the ID are both clearly visible.',
                  'Our team reviews submissions within 24 hours.',
                  'Once approved, a verified badge appears next to your name.',
                ].map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 15, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade800,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Photo preview / picker
          Center(
            child: state._selfie == null
                ? _EmptyPhotoBox(state: state)
                : _PhotoPreview(file: state._selfie!, state: state),
          ),

          if (state._error != null) ...[
            const SizedBox(height: 16),
            Text(
              state._error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: state._uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_outlined, size: 18),
              label: Text(state._uploading ? 'Uploading…' : 'Submit for Review'),
              onPressed: state._uploading ? null : state._submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotoBox extends StatelessWidget {
  final _PassengerIdentityVerificationScreenState state;

  const _EmptyPhotoBox({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No photo selected',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Camera'),
              onPressed: () => state._pickSelfie(ImageSource.camera),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined, size: 16),
              label: const Text('Gallery'),
              onPressed: () => state._pickSelfie(ImageSource.gallery),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final File file;
  final _PassengerIdentityVerificationScreenState state;

  const _PhotoPreview({required this.file, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            file,
            width: 240,
            height: 240,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Choose a different photo'),
          onPressed: () => _showSourceSheet(context),
        ),
      ],
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                state._pickSelfie(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                state._pickSelfie(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Success view
 * -------------------------------------------------------------------------- */

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline,
                  size: 40, color: Colors.green.shade600),
            ),
            const SizedBox(height: 24),
            const Text(
              'Submitted!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your selfie has been submitted for review. We\'ll have an answer within 24 hours. You\'ll receive a notification once a decision is made.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
