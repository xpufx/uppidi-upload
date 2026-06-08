import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uppidi_upload/core/history_service.dart';
import 'package:uppidi_upload/core/models/upload_record.dart';

void main() {
  const testBoxName = 'uploadHistory';

  setUpAll(() async {
    Hive.init('.hive_test_history_service');
    Hive.registerAdapter(UploadRecordAdapter());
    if (!Hive.isBoxOpen(testBoxName)) {
      await Hive.openBox<UploadRecord>(testBoxName);
    }
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk(testBoxName);
  });

  setUp(() async {
    final box = Hive.box<UploadRecord>(testBoxName);
    await box.clear();
  });

  UploadRecord record(String fileName, DateTime time) => UploadRecord(
        fileName: fileName,
        url: 'https://a.com/$fileName',
        providerId: 'mock',
        providerName: 'Mock',
        success: true,
        completedAt: time,
      );

  group('HistoryService', () {
    test('add and getAll returns records newest first', () async {
      final svc = HistoryService();
      final t1 = DateTime(2025, 1, 1);
      final t2 = DateTime(2025, 1, 2);

      await svc.add(record('old.txt', t1));
      await svc.add(record('new.txt', t2));

      final all = await svc.getAll();
      expect(all.length, 2);
      expect(all[0].record.fileName, 'new.txt');
      expect(all[1].record.fileName, 'old.txt');
    });

    test('count returns correct number', () async {
      final svc = HistoryService();
      expect(await svc.count(), 0);

      await svc.add(record('a.txt', DateTime.now()));
      expect(await svc.count(), 1);

      await svc.add(record('b.txt', DateTime.now()));
      expect(await svc.count(), 2);
    });

    test('delete removes a specific record', () async {
      final svc = HistoryService();
      await svc.add(record('remove.txt', DateTime(2025, 1, 1)));
      await svc.add(record('keep.txt', DateTime(2025, 1, 2)));

      expect(await svc.count(), 2);

      final all = await svc.getAll();
      final removeKey =
          all.firstWhere((r) => r.record.fileName == 'remove.txt').key;
      await svc.delete(removeKey);

      final remaining = await svc.getAll();
      expect(remaining.length, 1);
      expect(remaining[0].record.fileName, 'keep.txt');
    });

    test('clearAll removes all records', () async {
      final svc = HistoryService();
      await svc.add(record('a.txt', DateTime.now()));
      await svc.add(record('b.txt', DateTime.now()));

      await svc.clearAll();
      expect(await svc.count(), 0);
      expect(await svc.getAll(), isEmpty);
    });

    test('getAll returns empty when no records', () async {
      final svc = HistoryService();
      expect(await svc.getAll(), isEmpty);
    });

    test('add persists the record across instances', () async {
      final svc1 = HistoryService();
      await svc1.add(record('persist.txt', DateTime.now()));

      final svc2 = HistoryService();
      final all = await svc2.getAll();
      expect(all.length, 1);
      expect(all[0].record.fileName, 'persist.txt');
    });

    test('close releases box reference', () async {
      final svc = HistoryService();
      await svc.add(record('close.txt', DateTime.now()));
      await svc.close();
      expect(await svc.count(), 1);
    });
  });
}
