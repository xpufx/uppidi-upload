import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';

void main() {
  group('FileUploadRequest', () {
    test('requires fileName, sizeInBytes, dataStream', () {
      final request = FileUploadRequest(
        fileName: 'test.png',
        sizeInBytes: 1024,
        dataStream: Stream.empty(),
      );

      expect(request.fileName, 'test.png');
      expect(request.sizeInBytes, 1024);
    });

    test('mimeType is optional', () {
      final request = FileUploadRequest(
        fileName: 'test.png',
        sizeInBytes: 1024,
        dataStream: Stream.empty(),
        mimeType: 'image/png',
      );

      expect(request.mimeType, 'image/png');

      final noMime = FileUploadRequest(
        fileName: 'test.png',
        sizeInBytes: 1024,
        dataStream: Stream.empty(),
      );

      expect(noMime.mimeType, isNull);
    });
  });

  group('UploadResult', () {
    test('success result has url', () {
      final result = UploadResult(
        success: true,
        url: 'https://example.com/file.png',
        statusCode: 200,
      );

      expect(result.success, true);
      expect(result.url, 'https://example.com/file.png');
      expect(result.errorMessage, isNull);
    });

    test('failure result has errorMessage', () {
      final result = UploadResult(
        success: false,
        errorMessage: 'Upload failed',
        statusCode: 500,
      );

      expect(result.success, false);
      expect(result.errorMessage, 'Upload failed');
      expect(result.url, isNull);
    });

    test('defaults completedAt to now', () {
      final before = DateTime.now();
      final result = UploadResult(success: true, url: 'https://x.com');
      final after = DateTime.now();

      expect(result.completedAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(result.completedAt.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('allows custom completedAt', () {
      final customTime = DateTime(2025, 1, 1);
      final result = UploadResult(
        success: true,
        url: 'https://x.com',
        completedAt: customTime,
      );

      expect(result.completedAt, customTime);
    });
  });
}