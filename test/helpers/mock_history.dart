import 'package:uppidi_upload/core/history_service.dart';
import 'package:uppidi_upload/core/models/upload_record.dart';

class MockHistoryService implements HistoryService {
  final List<UploadRecord> records = [];
  final Map<int, UploadRecord> _storage = {};

  @override
  Future<void> add(UploadRecord record) async {
    records.add(record);
    _storage[_storage.length] = record;
  }

  @override
  Future<List<HistoryRecord>> getAll() async {
    return _storage.entries
        .map((e) => HistoryRecord(key: e.key, record: e.value))
        .toList();
  }

  @override
  Future<int> count() async => records.length;

  @override
  Future<void> delete(int key) async {
    final record = _storage.remove(key);
    if (record != null) records.remove(record);
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
    records.clear();
  }

  @override
  Future<void> close() async {}
}
