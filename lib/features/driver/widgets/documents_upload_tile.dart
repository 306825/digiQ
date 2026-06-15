import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/driver_documents_api.dart';

class DocumentUploadTile extends ConsumerStatefulWidget {
  final String title;
  final String type;
  final bool uploaded; // ✅ NEW (comes from parent)
  final void Function(String key) onUploaded;

  const DocumentUploadTile({
    super.key,
    required this.title,
    required this.type,
    required this.uploaded,
    required this.onUploaded,
  });

  @override
  ConsumerState<DocumentUploadTile> createState() => _DocumentUploadTileState();
}

class _DocumentUploadTileState extends ConsumerState<DocumentUploadTile> {
  bool uploading = false;

  String _resolveContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final bytes = file.bytes!;
    final contentType = _resolveContentType(file.extension);

    setState(() => uploading = true);

    try {
      final api = ref.read(driverDocumentsApiProvider);

      final signed = await api.getUploadUrl(
        type: widget.type,
        contentType: contentType,
      );
      await api.uploadToS3(
        uploadUrl: signed['uploadUrl'],
        bytes: bytes,
        contentType: contentType,
      );

      widget.onUploaded(signed['key']); // ✅ ONLY ONCE

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} uploaded'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Upload failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploaded = widget.uploaded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? Colors.green : Colors.grey.shade300,
        ),
        color: isUploaded ? Colors.green.withOpacity(0.05) : null,
      ),
      child: ListTile(
        leading: Icon(
          isUploaded ? Icons.check_circle : Icons.upload_file,
          color: isUploaded ? Colors.green : Colors.grey,
        ),
        title: Text(widget.title),
        subtitle: isUploaded
            ? const Text('Uploaded · tap to replace',
                style: TextStyle(color: Colors.green))
            : const Text('Tap to upload'),
        trailing: uploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isUploaded
                ? const Icon(Icons.edit_outlined, size: 18, color: Colors.green)
                : const Icon(Icons.chevron_right),
        onTap: uploading ? null : _pickAndUpload,
      ),
    );
  }
}
