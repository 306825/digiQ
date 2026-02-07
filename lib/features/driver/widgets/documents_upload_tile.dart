import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/driver_documents_api.dart';

class DocumentUploadTile extends ConsumerStatefulWidget {
  final String title;
  final String type;
  //final ValueChanged<String> onUploaded;
  final void Function(String key) onUploaded;

  const DocumentUploadTile(
      {super.key,
      required this.title,
      required this.type,
      required this.onUploaded});

  @override
  ConsumerState<DocumentUploadTile> createState() => _DocumentUploadTileState();
}

class _DocumentUploadTileState extends ConsumerState<DocumentUploadTile> {
  bool uploading = false;
  bool uploaded = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.image,
    );

    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final bytes = file.bytes!;
    final contentType = file.extension == 'png' ? 'image/png' : 'image/jpeg';

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

      uploaded = true; // ✅ mark local state
      widget.onUploaded(signed['key']); // ✅ notify parent

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.title} uploaded successfully')),
        );
        widget.onUploaded(signed['key']);
      }
    } catch (e, stack) {
      debugPrint('❌ Upload failed');
      debugPrint(e.toString());
      debugPrint(stack.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.upload_file),
      title: Text(widget.title),
      trailing: uploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: uploading ? null : _pickAndUpload,
    );
  }
}
