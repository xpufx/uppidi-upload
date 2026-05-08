import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/main.dart';

void main() {
  setUpAll(() async {
    Hive.init('.hive_test');
    await Hive.openBox<String>('settings');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsServiceProvider
              .overrideWith((ref) => InMemorySettingsService()),
        ],
        child: const UppidiApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdaptiveHomePage), findsOneWidget);
  });
}

/// Minimal in-memory settings for tests that don't need real Hive.
class InMemorySettingsService extends SettingsService {
  final Map<String, String> _store = {};

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> set(String key, String value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<Map<String, String>> readAll() async => Map.from(_store);
}
