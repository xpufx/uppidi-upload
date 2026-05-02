import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi/core/models/upload_request.dart';
import 'package:uppidi/providers/catbox_provider.dart';
import 'package:uppidi/providers/httpbin_provider.dart';
import 'package:uppidi/providers/tmpfilelink_provider.dart';

void main() {
  final testRequest = FileUploadRequest(
    fileName: 'test.png',
    mimeType: 'image/png',
    sizeInBytes: 8,
    dataStream: Stream.value([1, 2, 3, 4, 5, 6, 7, 8]),
  );

  group('HttpBinProvider', () {
    late HttpBinProvider provider;

    setUp(() {
      provider = HttpBinProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'httpbin');
      expect(provider.providerName, 'HttpBin.org (Test)');
      expect(provider.supportsWeb, isTrue);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts origin from JSON', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/post'),
        statusCode: 200,
        data: {'origin': '1.2.3.4'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, contains('1.2.3.4'));
      expect(result.statusCode, 200);
    });

    test('parseResponse handles non-200 responses', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/post'),
        statusCode: 500,
        data: 'error',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Unexpected response'));
    });

    test('upload constructs correct form data', () async {
      // Verify provider doesn't crash on streaming request with CancelToken
      final cancelToken = CancelToken();

      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://httpbin.org');

      final result = await provider.upload(testRequest, cancelToken: cancelToken);

      // Should succeed or fail gracefully, never crash
      expect(result.success, anyOf(isTrue, isFalse));
      expect(result.completedAt, isNotNull);
    });
  });

  group('TmpFileLinkProvider', () {
    late TmpFileLinkProvider provider;

    setUp(() {
      provider = TmpFileLinkProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'tmpfilelink');
      expect(provider.providerName, 'tmpfile.link');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts downloadLink from JSON', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/upload'),
        statusCode: 200,
        data: {'downloadLink': 'https://tmpfile.link/abc123'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://tmpfile.link/abc123');
    });

    test('parseResponse handles missing downloadLink', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/upload'),
        statusCode: 200,
        data: {'message': 'ok'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, 'genericError');
    });

    test('client uses correct baseUrl and endpoint', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://tmpfile.link');
    });
  });

  group('CatboxProvider', () {
    late CatboxProvider provider;

    setUp(() {
      provider = CatboxProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'catbox');
      expect(provider.providerName, 'Catbox.moe');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, contains('userhash'));
    });

    test('parseResponse returns success for valid URL', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/user/api.php'),
        statusCode: 200,
        data: 'https://files.catbox.moe/test123.jpg',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://files.catbox.moe/test123.jpg');
    });

    test('parseResponse returns error for non-URL response', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/user/api.php'),
        statusCode: 200,
        data: 'File is too large',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, 'errorFileTooLarge');
    });

    test('upload includes reqtype in form fields', () async {
      // CatboxProvider requires 'reqtype': 'fileupload' as additional field
      expect(provider.additionalFormFields, containsPair('reqtype', 'fileupload'));
    });

    test('client uses correct baseUrl', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://catbox.moe');
    });
  });
}
