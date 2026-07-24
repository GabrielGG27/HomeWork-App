import 'dart:io';

import 'package:homework_app/models/attachment.dart';
import 'package:path_provider/path_provider.dart';

class AttachmentStorageService {
  AttachmentStorageService._();

  static Future<Directory> _attachmentsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}attachments',
    );
    await directory.create(recursive: true);
    return directory;
  }

  static Future<File> persistFile({
    required String sourcePath,
    required String originalFilename,
  }) async {
    final directory = await _attachmentsDirectory();
    final extension = _fileExtension(originalFilename);
    final destination = File(
      '${directory.path}${Platform.pathSeparator}'
      '${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    return File(sourcePath).copy(destination.path);
  }

  static Future<void> deleteManagedFiles(
    Iterable<Attachment> attachments,
  ) async {
    final directory = await _attachmentsDirectory();
    final managedPrefix = '${directory.absolute.path}${Platform.pathSeparator}';

    for (final attachment in attachments) {
      final file = File(attachment.path);
      if (!file.absolute.path.startsWith(managedPrefix)) continue;

      try {
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // The attachment reference can still be removed even if cleanup fails.
      }
    }
  }

  static String _fileExtension(String filename) {
    final lastDot = filename.lastIndexOf('.');
    if (lastDot <= 0 || lastDot == filename.length - 1) return '';

    final extension = filename.substring(lastDot);
    return extension.length <= 16 ? extension : '';
  }
}
