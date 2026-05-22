import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'logging/log.dart';
import 'settings_service.dart';

final _log = Log('ExportImport');
const _secure = FlutterSecureStorage();

/// Exports all provider config and app settings to a JSON file selected
/// by the user. Returns the file path on success, null if cancelled.
Future<String?> exportConfig() async {
  _log.info('Export started');
  final data = <String, dynamic>{
    'version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'providers': <String, dynamic>{},
    'settings': <String, String>{},
  };

  // Read all secure storage keys (provider instances + credentials)
  try {
    final allSecure = await _secure.readAll();
    for (final entry in allSecure.entries) {
      if (entry.key.startsWith('provider_')) {
        (data['providers'] as Map<String, dynamic>)[entry.key] = entry.value;
      }
    }
    _log.info('Read ${allSecure.length} secure storage entries');
  } catch (e) {
    _log.error('Failed to read secure storage: $e', error: e);
    rethrow;
  }

  // Read all Hive settings
  try {
    final svc = SettingsService();
    final allSettings = await svc.readAll();
    for (final entry in allSettings.entries) {
      (data['settings'] as Map<String, String>)[entry.key] = entry.value;
    }
    _log.info('Read ${allSettings.length} settings entries');
  } catch (e) {
    _log.error('Failed to read settings: $e', error: e);
    rethrow;
  }

  final json = const JsonEncoder.withIndent('  ').convert(data);
  final jsonBytes = utf8.encode(json);

  // Pick save location and write file
  try {
    final outputFile = await FilePicker.saveFile(
      dialogTitle: 'Export config',
      fileName: 'uppidi-export.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(jsonBytes),
    );
    if (outputFile == null) {
      _log.info('Export cancelled by user');
      return null;
    }
    _log.info('Export saved to: $outputFile');
    return outputFile;
  } catch (e) {
    _log.error('File picker save failed: $e', error: e);
    rethrow;
  }
}

/// Imports provider config and app settings from a user-selected JSON file.
/// Replaces ALL existing provider data and settings. Returns a descriptive
/// string on success, or throws on failure.
Future<String> importConfig() async {
  _log.info('Import started');
  // Pick file to import
  FilePickerResult? result;
  try {
    result = await FilePicker.pickFiles(
      dialogTitle: 'Import config',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
  } catch (e) {
    _log.error('File picker failed: $e', error: e);
    rethrow;
  }
  if (result == null || result.files.isEmpty) {
    _log.info('Import cancelled by user');
    throw Exception('No file selected');
  }

  String fileContent;
  try {
    fileContent = await File(result.files.single.path!).readAsString();
  } catch (e) {
    _log.error('Failed to read selected file: $e', error: e);
    rethrow;
  }

  Map<String, dynamic> json;
  try {
    json = jsonDecode(fileContent) as Map<String, dynamic>;
  } catch (e) {
    _log.error('Failed to parse JSON: $e', error: e);
    rethrow;
  }

  if (json['version'] != 1) {
    final msg = 'Unsupported export version: ${json['version']}';
    _log.error(msg);
    throw Exception(msg);
  }

  final providers = json['providers'] as Map<String, dynamic>? ?? {};
  final settings = json['settings'] as Map<String, dynamic>? ?? {};

  // 1. Clear existing provider data in secure storage
  try {
    final allSecure = await _secure.readAll();
    int cleared = 0;
    for (final key in allSecure.keys) {
      if (key.startsWith('provider_')) {
        await _secure.delete(key: key);
        cleared++;
      }
    }
    _log.info('Cleared $cleared provider entries');
  } catch (e) {
    _log.error('Failed to clear provider storage: $e', error: e);
    rethrow;
  }

  // 2. Write imported provider data
  try {
    for (final entry in providers.entries) {
      await _secure.write(key: entry.key, value: entry.value as String);
    }
    _log.info('Wrote ${providers.length} provider keys');
  } catch (e) {
    _log.error('Failed to write provider config: $e', error: e);
    rethrow;
  }

  // 3. Clear and rewrite Hive settings
  try {
    final svc = SettingsService();
    final allSettings = await svc.readAll();
    for (final key in allSettings.keys) {
      await svc.remove(key);
    }
    for (final entry in settings.entries) {
      await svc.set(entry.key, entry.value as String);
    }
    _log.info('Restored ${settings.length} settings');
  } catch (e) {
    _log.error('Failed to restore settings: $e', error: e);
    rethrow;
  }

  _log.info('Import complete');
  return 'Import complete: ${providers.length} provider keys, ${settings.length} settings';
}
