import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/core/android_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.uppidi.uppidi/export_save');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('auto-detects mimeType from fileName', () {
    test('application/json for .json', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'application/json');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'uppidi-export.json');
    });

    test('image/jpeg for .jpg', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'image/jpeg');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.jpg');
    });

    test('image/jpeg for .jpeg', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'image/jpeg');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.jpeg');
    });

    test('image/png for .png', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'image/png');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.png');
    });

    test('image/png for .gif (fallback)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'image/png');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.gif');
    });

    test('image/png for .webp (fallback)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'image/png');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.webp');
    });

    test('image/tiff for .tiff', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'image/tiff');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.tiff');
    });

    test('image/tiff for .tif', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'image/tiff');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.tif');
    });
  });

  group('explicit mimeType override', () {
    test('overrides auto-detection', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'application/pdf');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.jpg',
          mimeType: 'application/pdf');
    });

    test('null override falls back to auto-detection', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        expect(call.arguments['mimeType'], 'image/png');
        return '/path/to/file';
      });

      await saveFileOnAndroid(Uint8List(0), 'test.png', mimeType: null);
    });
  });

  test('passes bytes and fileName to channel', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      expect(call.method, 'saveFile');
      expect(call.arguments['fileName'], 'test.jpg');
      expect(call.arguments['bytes'], isA<List<int>>());
      expect((call.arguments['bytes'] as List<int>), [1, 2, 3]);
      return '/path/to/file';
    });

    final result = await saveFileOnAndroid(bytes, 'test.jpg');
    expect(result, '/path/to/file');
  });

  test('returns null on MissingPluginException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      throw MissingPluginException('not implemented');
    });

    final result = await saveFileOnAndroid(Uint8List(0), 'test.jpg');
    expect(result, isNull);
  });
}
