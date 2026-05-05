import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/logging/log.dart';
import '../core/models/upload_record.dart';

final _log = Log('HistoryService');

class HistoryRecord {
  final int key;
  final UploadRecord record;

  HistoryRecord({required this.key, required this.record});
}

class HistoryService {
  static const _boxName = 'uploadHistory';
  Box<UploadRecord>? _box;

  Future<Box<UploadRecord>> get _boxReady async {
    _box ??= await Hive.openBox<UploadRecord>(_boxName);
    return _box!;
  }

  Future<void> add(UploadRecord record) async {
    try {
      final box = await _boxReady;
      await box.add(record);
      _log.info('Saved record: ${record.fileName}');
    } catch (e) {
      _log.warn('Failed to save history: $e', error: e);
    }
  }

  Future<List<HistoryRecord>> getAll() async {
    try {
      final box = await _boxReady;
      final pairs = box.toMap().entries.map((e) => HistoryRecord(
            key: e.key,
            record: e.value,
          ));
      final sorted = pairs.toList()
        ..sort((a, b) => b.record.completedAt.compareTo(a.record.completedAt));
      return sorted;
    } catch (e) {
      _log.warn('Failed to read history: $e', error: e);
      return [];
    }
  }

  Future<int> count() async {
    try {
      final box = await _boxReady;
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> delete(int key) async {
    try {
      final box = await _boxReady;
      await box.delete(key);
    } catch (e) {
      _log.warn('Failed to delete history: $e', error: e);
    }
  }

  Future<void> clearAll() async {
    try {
      final box = await _boxReady;
      await box.clear();
      _log.info('History cleared');
    } catch (e) {
      _log.warn('Failed to clear history: $e', error: e);
    }
  }
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService());
final uploadHistoryProvider = FutureProvider<List<HistoryRecord>>((ref) async {
  final svc = ref.read(historyServiceProvider);
  return svc.getAll();
});
