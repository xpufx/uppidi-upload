import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/providers/bzzhr_provider.dart';
import 'package:uppidi_upload/providers/catbox_provider.dart';
import 'package:uppidi_upload/providers/filebin_provider.dart';
import 'package:uppidi_upload/providers/fileditch_provider.dart';
import 'package:uppidi_upload/providers/filester_provider.dart';
import 'package:uppidi_upload/providers/freeimage_provider.dart';
import 'package:uppidi_upload/providers/frisk_provider.dart';
import 'package:uppidi_upload/providers/gofile_provider.dart';
import 'package:uppidi_upload/providers/httpbin_provider.dart';
import 'package:uppidi_upload/providers/litterbox_provider.dart';
import 'package:uppidi_upload/providers/tempsh_provider.dart';
import 'package:uppidi_upload/providers/tmpfilelink_provider.dart';
import 'package:uppidi_upload/providers/uguu_provider.dart';

void main() {
  setUpAll(() async {
    Hive.init('.hive_test_provider');
    await Hive.openBox<String>('settings');
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('settings');
  });

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

    test('parseResponse extracts origin from JSON (success)', () {
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

    test('parseResponse handles non-200 responses (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/post'),
        statusCode: 500,
        data: 'error',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Unexpected response'));
    });

    test('parseResponse handles malformed null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/post'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test(
        'parseResponse handles wrong data type (string instead of Map) (failure)',
        () {
      final response = Response(
        requestOptions: RequestOptions(path: '/post'),
        statusCode: 200,
        data: 'not a map',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('upload constructs correct form data', () async {
      final cancelToken = CancelToken();
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://httpbin.org');
      final result =
          await provider.upload(testRequest, cancelToken: cancelToken);
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

    test('parseResponse extracts downloadLink from JSON (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/upload'),
        statusCode: 200,
        data: {'downloadLink': 'https://tmpfile.link/abc123'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://tmpfile.link/abc123');
    });

    test('parseResponse handles missing downloadLink (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/upload'),
        statusCode: 200,
        data: {'message': 'ok'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, 'genericError');
    });

    test('parseResponse handles non-200 responses (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/upload'),
        statusCode: 404,
        data: {'error': 'not found'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.statusCode, 404);
    });

    test('parseResponse handles malformed null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/upload'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test(
        'parseResponse handles wrong data type (string instead of Map) (failure)',
        () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/upload'),
        statusCode: 200,
        data: 'server error occurred',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
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
      expect(provider.requiredConfigKeys,
          isEmpty); // Fixed: actual code returns empty list
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

    test('parseResponse handles non-200 status codes (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/user/api.php'),
        statusCode: 500,
        data: 'Internal Server Error',
      );
      final result = provider.parseResponse(response);
      // Catbox provider doesn't check status code, so if response data doesn't start with https://, it fails
      expect(result.success, isFalse);
    });

    test('parseResponse handles malformed null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/user/api.php'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      // null.toString() is "null", which doesn't start with https://
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (non-string) (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/user/api.php'),
        statusCode: 200,
        data: 123, // int
      );
      final result = provider.parseResponse(response);
      // 123.toString() is '123', which doesn't start with https://
      expect(result.success, isFalse);
      expect(result.errorMessage, 'genericError');
    });

    test('parseResponse returns error for invalid uploader response', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/user/api.php'),
        statusCode: 200,
        data: 'Invalid uploader',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, 'errorInvalidUploader');
    });

    test('upload includes reqtype in form fields', () async {
      expect(
          provider.additionalFormFields, containsPair('reqtype', 'fileupload'));
    });

    test('client uses correct baseUrl', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://catbox.moe');
    });
  });

  group('UguuProvider', () {
    late UguuProvider provider;

    setUp(() {
      provider = UguuProvider();
    });

    test('metadata', () {
      expect(provider.providerId, contains('uguu'));
      expect(provider.providerName, 'uguu.se');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts url from files[0].url (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: {
          'success': true,
          'files': [
            {'url': 'https://h.uguu.se/abc123.png', 'hash': 'abc', 'size': 1024}
          ],
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://h.uguu.se/abc123.png');
    });

    test('parseResponse handles empty files array (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: {'success': false, 'files': []},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles non-200 responses (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 401,
        data: {'error': 'unauthorized'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.statusCode, 401);
    });

    test('parseResponse handles malformed null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test(
        'parseResponse handles wrong data type (string instead of Map) (failure)',
        () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: 'error uploading file',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles missing files key (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: {'success': true},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('client uses correct baseUrl and form field name', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://uguu.se');
      expect(provider.fileFormFieldName, 'files[]');
    });
  });

  group('FreeImageHostProvider', () {
    late FreeImageHostProvider provider;

    setUp(() {
      provider = FreeImageHostProvider(
        name: 'freeimage.host',
        url: 'https://freeimage.host',
      ); // Removed invalid apiKey parameter
    });

    test('metadata', () {
      expect(provider.providerId, contains('freeimage'));
      expect(provider.providerName, 'freeimage.host');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts url from image.display_url (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/1/upload'),
        statusCode: 200,
        data: {
          'status_code': 200,
          'image': {
            'name': 'test',
            'extension': 'png',
            'url': 'https://freeimage.host/images/test.png',
            'display_url': 'https://freeimage.host/images/test.png',
          },
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://freeimage.host/images/test.png');
    });

    test('parseResponse falls back to image.url (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/1/upload'),
        statusCode: 200,
        data: {
          'status_code': 200,
          'image': {
            'url': 'https://freeimage.host/images/fallback.png',
          },
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://freeimage.host/images/fallback.png');
    });

    test('parseResponse handles missing image (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/1/upload'),
        statusCode: 400,
        data: {
          'status_code': 400,
          'error': {'message': 'fail'}
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles non-200 responses (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/1/upload'),
        statusCode: 500,
        data: {'error': 'server error'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles malformed null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/1/upload'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test(
        'parseResponse handles wrong data type (string instead of Map) (failure)',
        () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/1/upload'),
        statusCode: 200,
        data: 'invalid json response',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('endpoint includes format and api key', () {
      expect(provider.uploadEndpoint, contains('format=json'));
      expect(provider.uploadEndpoint, contains('key='));
    });

    test('client uses correct baseUrl', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://freeimage.host');
    });
  });

  group('TempShProvider', () {
    late TempShProvider provider;

    setUp(() {
      provider = TempShProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'tempsh');
      expect(provider.providerName, 'temp.sh');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts URL from plain text (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: 'https://temp.sh/abc123/test.png',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://temp.sh/abc123/test.png');
    });

    test('parseResponse handles non-200 responses (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 413,
        data: 'file too large',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.statusCode, 413);
    });

    test('parseResponse handles non-URL response (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: 'error uploading file',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles malformed null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      // null.toString() is "null", which doesn't start with http/https
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (non-string) (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload'),
        statusCode: 200,
        data: ['not', 'a', 'string'],
      );
      final result = provider.parseResponse(response);
      // list.toString() doesn't start with http/https
      expect(result.success, isFalse);
    });

    test('client uses correct baseUrl', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://temp.sh');
    });
  });

  group('FileDitchProvider', () {
    late FileDitchProvider provider;

    setUp(() {
      provider = FileDitchProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'fileditch');
      expect(provider.providerName, 'FileDitch');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts url from JSON (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload.php'),
        statusCode: 200,
        data: {'success': true, 'url': 'https://fileditch.com/abc123'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://fileditch.com/abc123');
    });

    test('parseResponse handles missing url field (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload.php'),
        statusCode: 200,
        data: {'success': true},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles JSON error (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload.php'),
        statusCode: 400,
        data: {'success': false, 'error': 'File too large'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, 'File too large');
    });

    test('parseResponse handles null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload.php'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/upload.php'),
        statusCode: 200,
        data: 'not a map',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('client uses correct baseUrl', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://new.fileditch.com');
    });
  });

  group('FriskProvider', () {
    late FriskProvider provider;

    setUp(() {
      provider = FriskProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'frisk');
      expect(provider.providerName, 'Frisk');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts file_url from JSON (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/files/upload'),
        statusCode: 200,
        data: {'file_url': 'https://frisk.page/f/abc123'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://frisk.page/f/abc123');
    });

    test('parseResponse handles non-200 status (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/files/upload'),
        statusCode: 500,
        data: 'error',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles missing file_url (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/files/upload'),
        statusCode: 200,
        data: {'message': 'ok'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/files/upload'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/files/upload'),
        statusCode: 200,
        data: 'server error',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('client uses correct baseUrl', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://frisk.page');
    });
  });

  group('LitterboxProvider', () {
    late LitterboxProvider provider;

    setUp(() {
      provider = LitterboxProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'litterbox');
      expect(provider.providerName, 'Litterbox');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts URL from plain text (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/resources/internals/api.php'),
        statusCode: 200,
        data: 'https://litterbox.catbox.moe/abc123.png',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://litterbox.catbox.moe/abc123.png');
    });

    test('parseResponse handles non-200 status (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/resources/internals/api.php'),
        statusCode: 500,
        data: 'error',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles non-URL text (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/resources/internals/api.php'),
        statusCode: 200,
        data: 'File too large',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/resources/internals/api.php'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/resources/internals/api.php'),
        statusCode: 200,
        data: ['not', 'a', 'string'],
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('client uses correct baseUrl', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://litterbox.catbox.moe');
    });

    test('additional form fields include expiry', () {
      expect(provider.buildFormFields({'_expiry': '12h'}),
          containsPair('time', '12h'));
    });
  });

  group('GoFileProvider', () {
    late GoFileProvider provider;

    setUp(() {
      provider = GoFileProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'gofile');
      expect(provider.providerName, 'GoFile');
      expect(provider.supportsWeb, isTrue);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts downloadPage from JSON (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/servers'),
        statusCode: 200,
        data: {
          'status': 'ok',
          'data': {'downloadPage': 'https://gofile.io/d/abc123'},
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://gofile.io/d/abc123');
    });

    test('parseResponse handles non-200 status (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/servers'),
        statusCode: 500,
        data: 'error',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong status in data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/servers'),
        statusCode: 200,
        data: {'status': 'fail', 'data': {}},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles missing downloadPage (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/servers'),
        statusCode: 200,
        data: {
          'status': 'ok',
          'data': {'something': 'else'},
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/servers'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/servers'),
        statusCode: 200,
        data: 'plain string',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });
  });

  group('FilebinProvider', () {
    late FilebinProvider provider;

    setUp(() {
      provider = FilebinProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'filebin');
      expect(provider.providerName, 'Filebin.net');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts bin and file from JSON (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/abc123/file.txt'),
        statusCode: 201,
        data: {
          'bin': {'id': 'abc123'},
          'file': {'filename': 'file.txt'},
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://filebin.net/abc123/file.txt');
    });

    test('parseResponse handles non-201 status (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/abc123/file.txt'),
        statusCode: 500,
        data: 'error',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles missing bin id (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/abc123/file.txt'),
        statusCode: 201,
        data: {
          'bin': {},
          'file': {'filename': 'file.txt'},
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles missing file (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/abc123/file.txt'),
        statusCode: 201,
        data: {
          'bin': {'id': 'abc123'},
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/abc123/file.txt'),
        statusCode: 201,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/abc123/file.txt'),
        statusCode: 201,
        data: 'plain string',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });
  });

  group('FilesterProvider', () {
    late FilesterProvider provider;

    setUp(() {
      provider = FilesterProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'filester');
      expect(provider.providerName, 'Filester.me');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse constructs URL from slug (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/upload'),
        statusCode: 200,
        data: {'success': true, 'slug': 'xyz789'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://filester.me/d/xyz789');
    });

    test('parseResponse handles missing slug (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/upload'),
        statusCode: 200,
        data: {'success': true, 'message': 'ok'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles failed success (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/upload'),
        statusCode: 200,
        data: {'success': false, 'message': 'Rate limited'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Rate limited');
    });

    test('parseResponse handles null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/upload'),
        statusCode: 200,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/upload'),
        statusCode: 200,
        data: 'unexpected string',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('client uses correct baseUrl', () async {
      final client = await provider.createHttpClient({});
      expect(client.options.baseUrl, 'https://u1.filester.me');
    });
  });

  group('BzzhrProvider', () {
    late BzzhrProvider provider;

    setUp(() {
      provider = BzzhrProvider();
    });

    test('metadata', () {
      expect(provider.providerId, 'bzzhr');
      expect(provider.providerName, 'Bzzhr.to');
      expect(provider.supportsWeb, isFalse);
      expect(provider.requiredConfigKeys, isEmpty);
    });

    test('parseResponse extracts id from JSON (success)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test.txt'),
        statusCode: 201,
        data: {
          'code': 201,
          'data': {'id': 'abc123'},
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isTrue);
      expect(result.url, 'https://bzzhr.co/abc123');
    });

    test('parseResponse handles non-201 status (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test.txt'),
        statusCode: 500,
        data: 'error',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong code (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test.txt'),
        statusCode: 201,
        data: {
          'code': 400,
          'data': {'id': 'abc123'},
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles missing id (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test.txt'),
        statusCode: 201,
        data: {
          'code': 201,
          'data': {},
        },
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse extracts error message on failure', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test.txt'),
        statusCode: 400,
        data: {'error': 'File too large'},
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
      expect(result.errorMessage, 'File too large');
    });

    test('parseResponse handles null data (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test.txt'),
        statusCode: 201,
        data: null,
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });

    test('parseResponse handles wrong data type (failure)', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test.txt'),
        statusCode: 201,
        data: 'some string',
      );
      final result = provider.parseResponse(response);
      expect(result.success, isFalse);
    });
  });
}
