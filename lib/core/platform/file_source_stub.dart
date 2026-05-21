import 'package:file_picker/file_picker.dart';

import '../mime_types.dart';
import '../models/upload_request.dart';

Future<FileUploadRequest> createUploadRequest(PlatformFile file) async {
  final bytes = file.bytes;
  if (bytes == null) {
    throw StateError('No file bytes available on web');
  }
  return FileUploadRequest(
    fileName: file.name,
    mimeType:
        file.extension != null ? mimeTypeFromExtension(file.extension!) : null,
    sizeInBytes: bytes.length,
    dataStream: Stream.value(bytes),
  );
}
