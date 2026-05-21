import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/core/models/provider_metadata.dart';
import 'package:uppidi_upload/core/models/upload_record.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/core/history_service.dart';
import 'package:uppidi_upload/providers/upload_provider.dart';

// Mock classes
class MockBaseUploader implements BaseUploader {
  Future<UploadResult> Function(FileUploadRequest,
      {UploadProgressCallback? onProgress,
      CancelToken? cancelToken,
      Map<String, String> config})? uploadCallback;
  final ProviderMetadata _metadata;
  final String _providerId;
  final String _providerName;
  final List<String> _requiredConfigKeys;
  final Map<String, String> _configLabels;
  final bool _supportsWeb;
  bool _uploadCalled = false;
  bool get uploadCalled => _uploadCalled;
  void resetUploadCalled() => _uploadCalled = false;

  MockBaseUploader({
    this.uploadCallback,
    ProviderMetadata? metadata,
    String providerId = 'mock_provider',
    String providerName = 'Mock Provider',
    List<String> requiredConfigKeys = const [],
    Map<String, String> configLabels = const {},
    bool supportsWeb = false,
  })  : _metadata = metadata ??
            const ProviderMetadata(maxFileSizeBytes: 10 * 1024 * 1024),
        _providerId = providerId,
        _providerName = providerName,
        _requiredConfigKeys = requiredConfigKeys,
        _configLabels = configLabels,
        _supportsWeb = supportsWeb;

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  bool get supportsWeb => _supportsWeb;

  @override
  List<String> get requiredConfigKeys => _requiredConfigKeys;

  @override
  Map<String, String> get configLabels => _configLabels;

  @override
  List<String> get optionalConfigKeys => const [];

  @override
  String? get proxyUrl => null;

  @override
  String? get instanceDescription => null;
  @override
  List<String> get optionalTextConfigKeys => const [];

  @override
  ProviderMetadata get metadata => _metadata;

  @override
  Future<Dio> createHttpClient(Map<String, String> config,
      {bool allowInsecureConn = false, String? proxyUrl}) async {
    return Dio();
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config = const {},
  }) async {
    _uploadCalled = true;
    if (uploadCallback != null) {
      return uploadCallback!(request,
          onProgress: onProgress, cancelToken: cancelToken, config: config);
    }
    return UploadResult(
        success: true,
        url: 'https://mock.url/${request.fileName}',
        completedAt: DateTime.now());
  }
}

class MockSettingsService implements SettingsService {
  @override
  Future<Map<String, String>> loadProviderConfig(
          String providerId, List<String> requiredKeys) async =>
      {};

  @override
  Future<bool> isInsecureConnAllowed() async => false;

  @override
  Future<String?> getProxyUrl() async => null;

  @override
  Future<String?> get(String key) async => null;

  @override
  Future<void> set(String key, String value) async {}

  @override
  Future<void> remove(String key) async {}

  @override
  Future<bool> containsKey(String key) async => false;

  @override
  Future<Map<String, String>> readAll() async => {};

  @override
  String providerKey(String providerId, String configKey) =>
      '$providerId.$configKey';

  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

  @override
  Future<Color> getSeedColor() async => const Color(0xFF6750A4);

  @override
  Future<String?> getLogoPath() async => null;

  @override
  Future<Set<String>> getDisabledProviders() async => {};

  @override
  Future<void> setDisabledProviders(Set<String> ids) async {}

  @override
  Future<bool> isDebugLoggingEnabled() async => false;

  @override
  Future<void> setDebugLoggingEnabled(bool enabled) async {}

  @override
  Future<Set<String>> getInsecureMutedProviders() async => {};

  @override
  Future<void> muteInsecureWarning(String providerId) async {}

  @override
  Future<bool> isInsecureWarningMuted(String providerId) async => false;

  @override
  Future<String> getNavigationLayout() async => 'bottom';

  @override
  Future<void> setNavigationLayout(String layout) async {}

  @override
  Future<String> getShellType() async => 'tabs';

  @override
  Future<void> setShellType(String type) async {}
}

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

// End mock classes

void main() {
  late Directory tempDir;
  late File testFile;
  late ProviderContainer container;
  late MockSettingsService mockSettings;
  late MockHistoryService mockHistory;
  late List<MockBaseUploader> mockUploaders;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('upload_test_');
    testFile = File('${tempDir.path}/test_file.txt');
    await testFile.writeAsString('test content');
    mockSettings = MockSettingsService();
    mockHistory = MockHistoryService();
    mockUploaders = [
      MockBaseUploader(providerId: 'mock_0', providerName: 'Mock Provider 0'),
      MockBaseUploader(providerId: 'mock_1', providerName: 'Mock Provider 1'),
    ];
    // Reset upload tracking
    for (final uploader in mockUploaders) {
      uploader.resetUploadCalled();
    }

    container = ProviderContainer(
      overrides: [
        enabledProvidersProvider.overrideWithValue(mockUploaders),
        settingsServiceProvider.overrideWithValue(mockSettings),
        historyServiceProvider.overrideWithValue(mockHistory),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await tempDir.delete(recursive: true);
  });

  group('State Machine Transitions', () {
    test('UploadIdle → UploadFileSelected after file selection', () async {
      final notifier = container.read(uploadProvider.notifier);
      expect(notifier.state, isA<UploadIdle>());

      await notifier.uploadFromFile(testFile.path, 'text/plain');
      expect(notifier.state, isA<UploadFileSelected>());
      final state = notifier.state as UploadFileSelected;
      expect(state.fileName, 'test_file.txt');
      expect(state.mimeType, 'text/plain');
      expect(state.fileSizeBytes, greaterThan(0));
    });

    test('UploadFileSelected → UploadInProgress on upload', () async {
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      expect(notifier.state, isA<UploadFileSelected>());

      // Set a slow upload to capture the InProgress state
      mockUploaders[0].uploadCallback =
          (request, {onProgress, cancelToken, config = const {}}) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return UploadResult(
            success: true,
            url: 'https://mock.url',
            completedAt: DateTime.now());
      };

      // Start upload without awaiting to check intermediate state
      final uploadFuture = notifier.uploadSelected();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state, isA<UploadInProgress>());
      final state = notifier.state as UploadInProgress;
      expect(state.progress, 0.0);
      expect(state.cancelToken, isNotNull);

      await uploadFuture; // Clean up
    });

    test('UploadInProgress → UploadCompleted on success', () async {
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();

      // Wait for upload to complete
      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state, isA<UploadCompleted>());
      final state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isTrue);
      expect(state.lastResult.url, contains('test_file.txt'));
    });

    test('UploadInProgress → UploadCompleted on upload failure', () async {
      mockUploaders[0].uploadCallback =
          (request, {onProgress, cancelToken, config = const {}}) async {
        return UploadResult(
            success: false,
            errorMessage: 'Upload failed',
            completedAt: DateTime.now());
      };
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state, isA<UploadCompleted>());
      final state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, 'Upload failed');
    });

    test('setProvider preserves file info across states', () async {
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      expect(notifier.state, isA<UploadFileSelected>());

      // Set provider in UploadFileSelected state
      notifier.setProvider(1);
      expect(notifier.state, isA<UploadFileSelected>());
      var state = notifier.state as UploadFileSelected;
      expect(state.selectedProviderIndex, 1);
      expect(state.fileName, 'test_file.txt');

      // Upload and complete, then set provider again
      await notifier.uploadSelected();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state, isA<UploadCompleted>());
      notifier.setProvider(0);
      expect(notifier.state, isA<UploadFileSelected>());
      state = notifier.state as UploadFileSelected;
      expect(state.selectedProviderIndex, 0);
      expect(state.fileName, 'test_file.txt');
    });
  });

  group('Error Paths', () {
    test('No providers configured → error state', () async {
      final emptyContainer = ProviderContainer(
        overrides: [
          enabledProvidersProvider.overrideWithValue([]),
          settingsServiceProvider.overrideWithValue(mockSettings),
          historyServiceProvider.overrideWithValue(mockHistory),
        ],
      );
      final notifier = emptyContainer.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state, isA<UploadCompleted>());
      final state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, 'noProvidersConfigured');
      emptyContainer.dispose();
    });

    test('File read failure → error state', () async {
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile('/nonexistent/file.txt', 'text/plain');

      expect(notifier.state, isA<UploadCompleted>());
      final state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, 'failedToReadFile');
    });

    test('Upload failure → error with retry possible', () async {
      mockUploaders[0].uploadCallback =
          (request, {onProgress, cancelToken, config = const {}}) async {
        return UploadResult(
            success: false,
            errorMessage: 'Server error',
            completedAt: DateTime.now());
      };
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state, isA<UploadCompleted>());
      var state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isFalse);

      // Retry with same file
      await notifier.uploadSelected();
      await Future.delayed(const Duration(milliseconds: 100));
      state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isFalse); // Still fails, but retry works
    });

    test('Cancel during upload → returns to idle', () async {
      // Create a slow upload to allow cancellation
      mockUploaders[0].uploadCallback =
          (request, {onProgress, cancelToken, config = const {}}) async {
        await Future.delayed(const Duration(seconds: 5));
        return UploadResult(
            success: true,
            url: 'https://mock.url',
            completedAt: DateTime.now());
      };
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();

      // Cancel immediately
      notifier.cancelUpload();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state, isA<UploadIdle>());
    });
  });

  group('Chain Uploads', () {
    test('After success, change provider, upload again with recreated stream',
        () async {
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state, isA<UploadCompleted>());
      var state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isTrue);
      expect(mockUploaders[0].uploadCalled, isTrue); // First provider was used

      // Change provider
      notifier.setProvider(1);
      expect(notifier.state, isA<UploadFileSelected>());
      // Reset upload tracking for second provider
      mockUploaders[1].resetUploadCalled();

      // Upload again with new provider
      await notifier.uploadSelected();
      await Future.delayed(const Duration(milliseconds: 100));
      state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isTrue);
      expect(mockUploaders[1].uploadCalled, isTrue); // Second provider was used
    });
  });

  group('clearSelection', () {
    test('Resets all state to idle', () async {
      final notifier = container.read(uploadProvider.notifier);
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      expect(notifier.state, isA<UploadFileSelected>());

      notifier.clearSelection();
      expect(notifier.state, isA<UploadIdle>());
      final state = notifier.state as UploadIdle;
      expect(state.selectedProviderIndex, 0); // Provider selection preserved
    });
  });

  group('UploadCompleted Regression Tests', () {
    test('Successful upload sets lastResult.url to expected value', () async {
      final notifier = container.read(uploadProvider.notifier);
      mockUploaders[0].uploadCallback =
          (request, {onProgress, cancelToken, config = const {}}) async {
        return UploadResult(
            success: true,
            url: 'https://example.com/test.png',
            completedAt: DateTime.now());
      };
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state, isA<UploadCompleted>());
      final state = notifier.state as UploadCompleted;
      expect(state.lastResult.url, isNotNull);
      expect(state.lastResult.url, 'https://example.com/test.png');
    });

    test('Successful upload sets isSuccess to true', () async {
      final notifier = container.read(uploadProvider.notifier);
      mockUploaders[0].uploadCallback =
          (request, {onProgress, cancelToken, config = const {}}) async {
        return UploadResult(
            success: true,
            url: 'https://example.com/test.png',
            completedAt: DateTime.now());
      };
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state, isA<UploadCompleted>());
      final state = notifier.state as UploadCompleted;
      expect(state.isSuccess, isTrue);
      expect(state.lastResult.success, isTrue);
    });

    test('Successful upload preserves file info in UploadCompleted', () async {
      final notifier = container.read(uploadProvider.notifier);
      mockUploaders[0].uploadCallback =
          (request, {onProgress, cancelToken, config = const {}}) async {
        return UploadResult(
            success: true,
            url: 'https://example.com/test.png',
            completedAt: DateTime.now());
      };
      const testMimeType = 'text/plain';
      await notifier.uploadFromFile(testFile.path, testMimeType);
      final expectedFileName = testFile.uri.pathSegments.last;
      final expectedFileSize = await testFile.length();

      await notifier.uploadSelected();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state, isA<UploadCompleted>());
      final state = notifier.state as UploadCompleted;
      expect(state.fileName, expectedFileName);
      expect(state.fileSizeBytes, expectedFileSize);
      expect(state.mimeType, testMimeType);
    });

    test(
        'setProvider preserves file info when transitioning from UploadCompleted',
        () async {
      final notifier = container.read(uploadProvider.notifier);
      mockUploaders[0].uploadCallback =
          (request, {onProgress, cancelToken, config = const {}}) async {
        return UploadResult(
            success: true,
            url: 'https://example.com/test.png',
            completedAt: DateTime.now());
      };
      await notifier.uploadFromFile(testFile.path, 'text/plain');
      await notifier.uploadSelected();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state, isA<UploadCompleted>());
      final completedState = notifier.state as UploadCompleted;
      final originalFileName = completedState.fileName;
      final originalFileSize = completedState.fileSizeBytes;
      final originalMimeType = completedState.mimeType;

      notifier.setProvider(1);

      expect(notifier.state, isA<UploadFileSelected>());
      final selectedState = notifier.state as UploadFileSelected;
      expect(selectedState.fileName, originalFileName);
      expect(selectedState.fileSizeBytes, originalFileSize);
      expect(selectedState.mimeType, originalMimeType);
      expect(selectedState.selectedProviderIndex, 1);
    });
  });
}
