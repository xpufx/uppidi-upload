import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../mime_types.dart';
import '../models/upload_request.dart';

Future<FileUploadRequest> createUploadRequest(PlatformFile file) async {
  if (file.path == null) {
    throw StateError('No file path available');
  }
  final ioFile = File(file.path!);
  final size = await ioFile.length();
  final stream = ioFile.openRead();

  return FileUploadRequest(
    fileName: file.name,
    mimeType:
        file.extension != null ? mimeTypeFromExtension(file.extension!) : null,
    sizeInBytes: size,
    dataStream: stream,
  );
}
