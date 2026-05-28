import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'android_save.dart';
import 'config_provider.dart';
import 'logging/log.dart';
import 'models/provider_instance.dart';
import 'provider_storage_service.dart';
import 'registry.dart';
import 'settings_service.dart';

final _log = Log('ExportImport');
const _secure = FlutterSecureStorage();

/// Builds the v2 export data map and returns it as a pretty-printed JSON
/// string.  Returns null if reading data fails.
Future<String?> buildExportJsonString({WidgetRef? ref}) async {
  try {
    final providers = <Map<String, dynamic>>[];

    if (ref != null) {
      for (final p in ProviderRegistry.all) {
        try {
          final cfg =
              await ref.read(providerConfigProvider(p.providerId).future);
          if (cfg.isEmpty) continue;

          final baseId = p.providerId.split('__').first;
          final entry = <String, dynamic>{
            'base_id': baseId,
            'config': cfg,
          };

          if (p is ProviderInstance) {
            entry['instance_id'] = p.instanceId;
            entry['instance_name'] = p.instanceName;
          }

          providers.add(entry);
        } catch (_) {}
      }
    }

    final svc = SettingsService();
    final allSettings = await svc.readAll();

    final data = <String, dynamic>{
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'providers': providers,
      'settings': allSettings,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (e) {
    _log.error('Failed to build export JSON: $e', error: e);
    return null;
  }
}

/// Exports all provider config and app settings to a JSON file selected
/// by the user. Returns the file path on success, null if cancelled.
Future<String?> exportConfig({WidgetRef? ref}) async {
  _log.info('Export started');
  final jsonString = await buildExportJsonString(ref: ref);
  if (jsonString == null) throw Exception('Failed to build export data');

  final jsonBytes = utf8.encode(jsonString);

  if (Platform.isAndroid) {
    return saveFileOnAndroid(
      Uint8List.fromList(jsonBytes),
      'uppidi-export.json',
    );
  }

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

/// Imports provider config and app settings from a user-selected JSON file
/// (v2 format). Replaces ALL existing provider data and settings.
Future<String> importConfig({WidgetRef? ref}) async {
  _log.info('Import started');

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
    fileContent = String.fromCharCodes(await result.files.single.readAsBytes());
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

  if (json['version'] != 2) {
    final msg = 'Unsupported export version: ${json['version']}';
    _log.error(msg);
    throw Exception(msg);
  }

  final providers =
      (json['providers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  final settings = json['settings'] as Map<String, dynamic>? ?? {};

  // 1. Clear all existing provider data in secure storage
  try {
    final allKeys = await _secure.readAll();
    int cleared = 0;
    for (final key in allKeys.keys) {
      if (key.startsWith('provider_config_') ||
          key.startsWith('provider_instances_')) {
        await _secure.delete(key: key);
        cleared++;
      }
    }
    _log.info('Cleared $cleared existing provider entries');
  } catch (e) {
    _log.error('Failed to clear provider storage: $e', error: e);
    rethrow;
  }

  // 2. Write imported provider config + build instance metadata
  try {
    final instanceGroups = <String, List<ProviderInstanceMeta>>{};
    int writtenKeys = 0;

    for (final prov in providers) {
      final baseId = prov['base_id'] as String;
      final instanceId = prov['instance_id'] as String?;
      final instanceName = prov['instance_name'] as String?;
      final config = prov['config'] as Map<String, dynamic>? ?? {};

      final pid = instanceId != null ? '${baseId}__$instanceId' : baseId;

      for (final e in config.entries) {
        await _secure.write(
          key: configStorageKey(pid, e.key),
          value: e.value as String,
        );
        writtenKeys++;
      }

      if (instanceId != null && instanceName != null) {
        instanceGroups.putIfAbsent(baseId, () => []).add(
              ProviderInstanceMeta(id: instanceId, name: instanceName),
            );
      }
    }

    for (final group in instanceGroups.entries) {
      await saveProviderInstances(group.key, group.value);
    }

    _log.info('Wrote $writtenKeys config keys, '
        '${instanceGroups.length} instance groups');
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

  // 4. Refresh provider registry so auth providers appear immediately
  if (ref != null) {
    await ProviderRegistry.refresh(ref);
  }

  _log.info('Import complete');
  return 'Import complete: ${providers.length} providers, '
      '${settings.length} settings';
}
