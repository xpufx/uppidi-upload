import 'package:flutter/services.dart';

// TODO: Remove this file after file_picker 12.x stable ships with a fix.
// file_picker 12.x betas removed "bytes" from the Android method channel
// arguments for saveFile (regression from 11.0.2), causing
// PathNotFoundException on content URIs.
// Once upstream is fixed, revert export_import.dart to
// FilePicker.saveFile(bytes: ...).

const _channel = MethodChannel('com.uppidi.uppidi/export_save');

Future<String?> saveFileOnAndroid(
  Uint8List bytes,
  String fileName, {
  String mimeType = 'application/json',
}) async {
  try {
    final path = await _channel.invokeMethod<String>('saveFile', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
    });
    return path;
  } on MissingPluginException {
    // Not running on Android (e.g. test), return null
    return null;
  }
}
