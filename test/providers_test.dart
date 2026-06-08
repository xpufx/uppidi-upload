import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/providers/custom_uguu_provider.dart';
import 'package:uppidi_upload/providers/gofile_provider.dart';
import 'package:uppidi_upload/providers/tmpfilelink_provider.dart';
import 'package:uppidi_upload/providers/httpbin_provider.dart';
import 'package:uppidi_upload/providers/telegram_provider.dart';
import 'package:uppidi_upload/providers/filester_provider.dart';
import 'package:uppidi_upload/providers/filebin_provider.dart';
import 'package:uppidi_upload/providers/storage_to_provider.dart';
import 'package:uppidi_upload/providers/bzzhr_provider.dart';
import 'package:uppidi_upload/core/registry.dart';

final _skipLive = Platform.environment.containsKey('SKIP_LIVE_TESTS');

void main() {
  group('ProviderRegistry', () {
    test('contains providers', () {
      expect(ProviderRegistry.all.isNotEmpty, true);
    });

    test('all providers implement BaseUploader', () {
      for (final provider in ProviderRegistry.all) {
        expect(provider.providerId, isNotEmpty);
        expect(provider.providerName, isNotEmpty);
      }
    });
  });

  group('TmpFileLinkProvider', () {
    late TmpFileLinkProvider provider;

    setUp(() {
      provider = TmpFileLinkProvider();
    });

    test('has correct metadata', () {
      expect(provider.providerId, 'tmpfilelink');
      expect(provider.providerName, 'tmpfile.link');
      expect(provider.supportsWeb, false);
      expect(provider.requiredConfigKeys, isEmpty);
      expect(provider.proxyUrl, isNull);
    });

    test('upload success - small text file', () async {
      final testData = Uint8List.fromList('Hello, test!'.codeUnits);
      final stream = Stream.value(testData);
      final request = FileUploadRequest(
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeInBytes: testData.length,
        dataStream: stream,
      );

      final result = await provider.upload(request);

      expect(result.success, true,
          reason: 'Expected success: ${result.errorMessage}');
      expect(result.url, isNotNull);
      expect(result.url, contains('tmpfile.link'));
      expect(result.statusCode, 200);
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: _skipLive ? 'Skipped via SKIP_LIVE_TESTS' : null);

    test('upload returns download link in response', () async {
      final testData = Uint8List.fromList('Test content'.codeUnits);
      final stream = Stream.value(testData);
      final request = FileUploadRequest(
        fileName: 'test_upload.txt',
        mimeType: 'text/plain',
        sizeInBytes: testData.length,
        dataStream: stream,
      );

      final result = await provider.upload(request);

      expect(result.url, isNotNull);
      expect(result.url, startsWith('https://'));
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: _skipLive ? 'Skipped via SKIP_LIVE_TESTS' : null);
  });

  group('HttpBinProvider', () {
    late HttpBinProvider provider;

    setUp(() {
      provider = HttpBinProvider();
    });

    test('has correct metadata', () {
      expect(provider.providerId, 'httpbin');
      expect(provider.providerName, 'HttpBin.org (Test)');
    });

    test('upload success - echo response', () async {
      final testData = Uint8List.fromList('Hello httpbin!'.codeUnits);
      final stream = Stream.value(testData);
      final request = FileUploadRequest(
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeInBytes: testData.length,
        dataStream: stream,
      );

      final result = await provider.upload(request);

      expect(result.statusCode, 200);
      expect(result.success, true);
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: _skipLive ? 'Skipped via SKIP_LIVE_TESTS' : null);
  });

  group('supportsMessage', () {
    test('default is false for all registry providers', () {
      for (final provider in ProviderRegistry.all) {
        final shouldSupport = <String>{
          'telegram',
          'zulip',
          'matterbridge',
        }.contains(provider.providerId);
        expect(provider.supportsMessage, shouldSupport,
            reason:
                '${provider.providerId} should supportMessage=$shouldSupport');
      }
    });

    test('Telegram supports messages', () {
      final provider = TelegramProvider();
      expect(provider.supportsMessage, true);
    });
  });

  group('GoFileProvider', () {
    test('has correct metadata', () {
      final provider = GoFileProvider();
      expect(provider.providerId, 'gofile');
      expect(provider.providerName, 'GoFile');
      expect(provider.supportsWeb, true);
      expect(provider.supportsMessage, false);
      expect(provider.metadata.supportsDirectLink, false);
      expect(provider.metadata.maxFileSizeBytes, isNull);
    });
  });

  group('FilesterProvider', () {
    late FilesterProvider provider;

    setUp(() {
      provider = FilesterProvider();
    });

    test('upload succeeds', () async {
      final data = Uint8List.fromList('hello filester'.codeUnits);
      final request = FileUploadRequest(
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeInBytes: data.length,
        dataStream: Stream.value(data),
      );

      final result = await provider.upload(request);

      if (!result.success) {
        fail(
            'Request failed (${result.statusCode}): ${result.errorMessage} | ${result.rawError}');
      }
      expect(result.url, contains('filester.me'));
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: _skipLive ? 'Skipped via SKIP_LIVE_TESTS' : null);
  });

  group('FilebinProvider', () {
    late FilebinProvider provider;

    setUp(() {
      provider = FilebinProvider();
    });

    test('upload succeeds', () async {
      final data = Uint8List.fromList('hello filebin'.codeUnits);
      final request = FileUploadRequest(
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeInBytes: data.length,
        dataStream: Stream.value(data),
      );

      final result = await provider.upload(request);

      if (!result.success) {
        fail(
            'Request failed (${result.statusCode}): ${result.errorMessage} | ${result.rawError}');
      }
      expect(result.url, contains('filebin.net'));
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: _skipLive ? 'Skipped via SKIP_LIVE_TESTS' : null);
  });

  group('StorageToProvider', () {
    late StorageToProvider provider;

    setUp(() {
      provider = StorageToProvider();
    });

    test('upload succeeds', () async {
      final data = Uint8List.fromList('hello storage.to'.codeUnits);
      final request = FileUploadRequest(
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeInBytes: data.length,
        dataStream: Stream.value(data),
      );

      final result = await provider.upload(request);

      if (!result.success) {
        fail(
            'Request failed (${result.statusCode}): ${result.errorMessage} | ${result.rawError}');
      }
      expect(result.url, contains('storage.to'));
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: _skipLive ? 'Skipped via SKIP_LIVE_TESTS' : null);
  });

  group('BzzhrProvider', () {
    late BzzhrProvider provider;

    setUp(() {
      provider = BzzhrProvider();
    });

    test('upload succeeds', () async {
      final data = Uint8List.fromList('hello bzzhr'.codeUnits);
      final request = FileUploadRequest(
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeInBytes: data.length,
        dataStream: Stream.value(data),
      );

      final result = await provider.upload(request);

      if (!result.success) {
        fail(
            'Request failed (${result.statusCode}): ${result.errorMessage} | ${result.rawError}');
      }
      expect(result.url, contains('bzzhr.'));
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: _skipLive ? 'Skipped via SKIP_LIVE_TESTS' : null);
  });

  group('CustomUguuProvider', () {
    late CustomUguuProvider provider;

    setUp(() {
      provider = CustomUguuProvider();
    });

    test('has correct metadata', () {
      expect(provider.providerId, 'custom_uguu');
      expect(provider.providerName, 'Uguu-like');
      expect(provider.requiredConfigKeys, ['server_url']);
    });

    test('upload succeeds against own instance', () async {
      final data = Uint8List.fromList('custom uguu test'.codeUnits);
      final request = FileUploadRequest(
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeInBytes: data.length,
        dataStream: Stream.value(data),
      );

      final result = await provider.upload(
        request,
        config: {'server_url': 'https://uguufiles.milan.xpufx.com'},
      );

      if (!result.success) {
        fail(
            'Custom Uguu upload failed (${result.statusCode}): ${result.errorMessage} | ${result.rawError}');
      }
      expect(result.url, startsWith('https://uguufiles.milan.xpufx.com'));
      expect(result.statusCode, 200);
    },
        timeout: const Timeout(Duration(minutes: 2)),
        skip: _skipLive ? 'Skipped via SKIP_LIVE_TESTS' : null);
  });
}
