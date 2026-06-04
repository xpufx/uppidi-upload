import 'package:flutter/services.dart';

// TODO: Remove this file after file_picker 12.x stable ships with a fix.
// file_picker 12.x betas removed "bytes" from the Android method channel
// arguments for saveFile (regression from 11.0.2), causing
// PathNotFoundException on content URIs.
// Once upstream is fixed, revert export_import.dart to
// FilePicker.saveFile(bytes: ...).

const _channel = MethodChannel('com.uppidi.uppidi/export_save');

/// Detects MIME type from [fileName] extension.
String _mimeFromName(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'gif' || 'webp' || 'bmp' || 'ico' => 'image/png',
    'tiff' || 'tif' => 'image/tiff',
    'jpg' || 'jpeg' => 'image/jpeg',
    'json' => 'application/json',
    _ => 'application/octet-stream',
  };
}

/// Saves [bytes] to a user-chosen location using the Android storage access
/// framework.  [mimeType] is auto-detected from [fileName]; override only if
/// the file extension doesn't reflect the true content.
Future<String?> saveFileOnAndroid(
  Uint8List bytes,
  String fileName, {
  String? mimeType,
}) async {
  try {
    final path = await _channel.invokeMethod<String>('saveFile', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType ?? _mimeFromName(fileName),
    });
    return path;
  } on MissingPluginException {
    return null;
  }
}
