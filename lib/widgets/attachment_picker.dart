import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:homework_app/models/attachment.dart';

class AttachmentPicker extends StatefulWidget {
  final List<Attachment> initialAttachments;
  final ValueChanged<List<Attachment>> onChanged;

  const AttachmentPicker({
    Key? key,
    this.initialAttachments = const [],
    required this.onChanged,
  }) : super(key: key);

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {
  late List<Attachment> _attachments;

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.initialAttachments);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final att = Attachment(
          id: '${DateTime.now().millisecondsSinceEpoch}-${picked.path.hashCode}',
          type: 'photo',
          path: picked.path,
          filename: picked.name,
        );
        setState(() => _attachments.add(att));
        widget.onChanged(_attachments);
      }
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        for (final f in result.files) {
          final path = f.path;
          if (path == null) continue;
          final att = Attachment(
            id: '${DateTime.now().millisecondsSinceEpoch}-${path.hashCode}',
            type: 'file',
            path: path,
            filename: f.name,
            mimeType: f.extension,
            size: f.size,
          );
          _attachments.add(att);
        }
        setState(() {});
        widget.onChanged(_attachments);
      }
    } catch (e) {
      // ignore
    }
  }

  void _removeAttachment(String id) {
    setState(() {
      _attachments = _attachments.where((a) => a.id != id).toList();
    });
    widget.onChanged(_attachments);
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
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(),
                            body: Center(child: Image.file(File(a.path))),
                          ),
                        ));
                      }
                    },
                    child: Image.file(
                      File(a.path),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
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
                  const Icon(Icons.insert_drive_file, size: 28),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.filename, overflow: TextOverflow.ellipsis)),
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
