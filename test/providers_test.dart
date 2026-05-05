import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/providers/tmpfilelink_provider.dart';
import 'package:uppidi_upload/providers/httpbin_provider.dart';
import 'package:uppidi_upload/core/registry.dart';

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
      // Create a small test file in memory
      final testData = Uint8List.fromList('Hello, test!'.codeUnits);
      final stream = Stream.value(testData);

      final request = FileUploadRequest(
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeInBytes: testData.length,
        dataStream: stream,
      );

      final result = await provider.upload(request);

      expect(result.success, true, reason: 'Expected success: ${result.errorMessage}');
      expect(result.url, isNotNull);
      expect(result.url, contains('tmpfile.link'));
      expect(result.statusCode, 200);
    }, timeout: const Timeout(Duration(minutes: 2)));

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
    }, timeout: const Timeout(Duration(minutes: 2)));
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

      // httpbin returns the URL in a different format
      expect(result.statusCode, 200);
      expect(result.success, true);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}