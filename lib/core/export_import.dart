import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'settings_service.dart';

const _secure = FlutterSecureStorage();

/// Exports all provider config and app settings to a JSON file selected
/// by the user. Returns the file path on success, null if cancelled.
Future<String?> exportConfig() async {
  final data = <String, dynamic>{
    'version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'providers': <String, dynamic>{},
    'settings': <String, String>{},
  };

  // Read all secure storage keys (provider instances + credentials)
  final allSecure = await _secure.readAll();
  for (final entry in allSecure.entries) {
    if (entry.key.startsWith('provider_')) {
      (data['providers'] as Map<String, dynamic>)[entry.key] = entry.value;
    }
  }

  // Read all Hive settings
  final svc = SettingsService();
  final allSettings = await svc.readAll();
  for (final entry in allSettings.entries) {
    (data['settings'] as Map<String, String>)[entry.key] = entry.value;
  }

  final json = const JsonEncoder.withIndent('  ').convert(data);
  final jsonBytes = utf8.encode(json);

  // Pick save location and write file (bytes parameter required on Android/iOS)
  final outputFile = await FilePicker.saveFile(
    dialogTitle: 'Export config',
    fileName: 'uppidi-export.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
    bytes: Uint8List.fromList(jsonBytes),
  );
  if (outputFile == null) return null;

  // On desktop the picker returns the path but doesn't write — do it here.
  // On mobile the picker already wrote the bytes, so this is a no-op overwrite.
  final file = File(outputFile);
  await file.parent.create(recursive: true);
  await file.writeAsString(json);
  return outputFile;
}

/// Imports provider config and app settings from a user-selected JSON file.
/// Replaces ALL existing provider data and settings. Returns a descriptive
/// string on success, or throws on failure.
Future<String> importConfig() async {
  // Pick file to import
  final result = await FilePicker.pickFiles(
    dialogTitle: 'Import config',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) {
    throw Exception('No file selected');
  }

  final file = File(result.files.single.path!);
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

  if (json['version'] != 1) {
    throw Exception('Unsupported export version: ${json['version']}');
  }

  final providers = json['providers'] as Map<String, dynamic>? ?? {};
  final settings = json['settings'] as Map<String, dynamic>? ?? {};

  // 1. Clear existing provider data in secure storage
  final allSecure = await _secure.readAll();
  for (final key in allSecure.keys) {
    if (key.startsWith('provider_')) {
      await _secure.delete(key: key);
    }
  }

  // 2. Write imported provider data
  for (final entry in providers.entries) {
    await _secure.write(key: entry.key, value: entry.value as String);
  }

  // 3. Clear and rewrite Hive settings
  final svc = SettingsService();
  final allSettings = await svc.readAll();
  for (final key in allSettings.keys) {
    await svc.remove(key);
  }
  for (final entry in settings.entries) {
    await svc.set(entry.key, entry.value as String);
  }

  return 'Import complete: ${providers.length} provider keys, ${settings.length} settings';
}
