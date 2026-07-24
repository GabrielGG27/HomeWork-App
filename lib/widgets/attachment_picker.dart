import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:homework_app/models/attachment.dart';
import 'package:homework_app/services/attachment_storage_service.dart';

class AttachmentPicker extends StatefulWidget {
  final List<Attachment> initialAttachments;
  final ValueChanged<List<Attachment>> onChanged;

  const AttachmentPicker({
    super.key,
    this.initialAttachments = const [],
    required this.onChanged,
  });

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {
  late List<Attachment> _attachments;
  late final Set<String> _initialAttachmentIds;

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.initialAttachments);
    _initialAttachmentIds = widget.initialAttachments.map((a) => a.id).toSet();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final storedFile = await AttachmentStorageService.persistFile(
          sourcePath: picked.path,
          originalFilename: picked.name,
        );
        final att = Attachment(
          id: '${DateTime.now().millisecondsSinceEpoch}-${storedFile.path.hashCode}',
          type: 'photo',
          path: storedFile.path,
          filename: picked.name,
        );
        if (!mounted) {
          await AttachmentStorageService.deleteManagedFiles([att]);
          return;
        }
        setState(() => _attachments.add(att));
        widget.onChanged(List.unmodifiable(_attachments));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save image: $error')),
      );
    }
  }

  Future<void> _pickFiles() async {
    final copiedAttachments = <Attachment>[];
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        for (final f in result.files) {
          final path = f.path;
          if (path == null) continue;
          final storedFile = await AttachmentStorageService.persistFile(
            sourcePath: path,
            originalFilename: f.name,
          );
          final att = Attachment(
            id: '${DateTime.now().millisecondsSinceEpoch}-${storedFile.path.hashCode}',
            type: 'file',
            path: storedFile.path,
            filename: f.name,
            mimeType: f.extension,
            size: f.size,
          );
          copiedAttachments.add(att);
        }
        if (!mounted) {
          await AttachmentStorageService.deleteManagedFiles(copiedAttachments);
          return;
        }
        setState(() => _attachments.addAll(copiedAttachments));
        widget.onChanged(List.unmodifiable(_attachments));
      }
    } catch (error) {
      await AttachmentStorageService.deleteManagedFiles(copiedAttachments);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save file: $error')),
      );
    }
  }

  void _removeAttachment(String id) {
    final removed = _attachments.where((a) => a.id == id).toList();
    setState(() {
      _attachments = _attachments.where((a) => a.id != id).toList();
    });
    widget.onChanged(List.unmodifiable(_attachments));

    if (!_initialAttachmentIds.contains(id)) {
      unawaited(AttachmentStorageService.deleteManagedFiles(removed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Take photo',
              icon: const Icon(Icons.camera_alt),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            IconButton(
              tooltip: 'Pick image',
              icon: const Icon(Icons.photo_library),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            IconButton(
              tooltip: 'Attach file',
              icon: const Icon(Icons.attach_file),
              onPressed: _pickFiles,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _attachments.map((a) {
            if (a.type == 'photo') {
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (a.path.isNotEmpty) {
                        final image = File(a.path);
                        if (image.existsSync()) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(),
                              body: Center(
                                child: Image.file(
                                  image,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.broken_image, size: 64),
                                ),
                              ),
                            ),
                          ));
                        }
                      }
                    },
                    child: Image.file(
                      File(a.path),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 96,
                        height: 96,
                        child: Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => _removeAttachment(a.id),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              );
            }

            // files
            return Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => OpenFile.open(a.path),
                    child: const Icon(Icons.insert_drive_file, size: 28),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => OpenFile.open(a.path),
                      child: Text(a.filename, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  InkWell(
                    onTap: () => _removeAttachment(a.id),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
