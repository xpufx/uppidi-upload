import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'android_save.dart';

/// Cross-platform file save.  Uses the Android Storage Access Framework on
/// Android, [FilePicker.saveFile] everywhere else.
///
/// Returns the saved path on success, `null` if the user cancelled.
Future<String?> saveFileCrossPlatform(
  Uint8List bytes,
  String fileName, {
  String? dialogTitle,
  required List<String> allowedExtensions,
  String? mimeType,
}) async {
  if (Platform.isAndroid) {
    return saveFileOnAndroid(bytes, fileName, mimeType: mimeType);
  }

  return FilePicker.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    bytes: bytes,
  );
}
