import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/logging/log.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import 'storage_to_config.dart';

class StorageToProvider extends BaseHttpProvider {
  late final Log _log = Log(runtimeType.toString());

  @override
  String get providerId => 'storage_to';

  @override
  String get providerName => 'Storage.to';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

  @override
  String get baseUrl => 'https://storage.to';

  @override
  String get uploadEndpoint => '/api/upload/init';

  @override
  String get fileFormFieldName => '';

  @override
  Map<String, String> get additionalFormFields => {};

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Object? config,
  }) async {
    try {
      final cfg = config is StorageToConfig ? config : const StorageToConfig();
      final rawConfig = cfg.data;
      final allowInsecure = rawConfig['_allow_insecure_conn'] == 'true';
      final proxyUrl = rawConfig['_proxy_url'];
      final userAgent = rawConfig['_user_agent'];
      final cleanConfig = Map<String, String>.from(rawConfig)
        ..remove('_allow_insecure_conn')
        ..remove('_proxy_url')
        ..remove('_user_agent');
      final dio = await createHttpClient(cleanConfig,
          allowInsecureConn: allowInsecure,
          proxyUrl: proxyUrl,
          userAgent: userAgent);

      final visitorToken = _randomToken();

      // Step 1: Init
      _log.info('init: POST /api/upload/init');
      final initResponse = await dio.post(
        '/api/upload/init',
        data: {
          'filename': request.fileName,
          'content_type': request.mimeType ?? 'application/octet-stream',
          'size': request.sizeInBytes,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-Visitor-Token': visitorToken,
        }),
      );

      final initData = initResponse.data;
      _log.info('init response: ${_trim(jsonEncode(initData))}');
      if (initData is! Map || initData['success'] != true) {
        final msg = initData is Map
            ? initData['error']?.toString() ?? initData.toString()
            : 'unknown';
        return UploadResult(
          success: false,
          errorMessage: msg,
          statusCode: initResponse.statusCode,
        );
      }

      final r2Key = initData['r2_key']?.toString();
      final uploadUrl = initData['upload_url']?.toString();
      final ownerToken = initData['owner_token']?.toString();
      if (r2Key == null || uploadUrl == null) {
        final missing = <String>[
          if (r2Key == null) 'r2_key',
          if (uploadUrl == null) 'upload_url',
        ];
        return UploadResult(
          success: false,
          errorMessage: 'Missing fields in init response: $missing',
          statusCode: initResponse.statusCode,
        );
      }

      // Forward any required headers from the init response (e.g. S3 Host)
      final putHeaders = <String, String>{
        'Content-Type': request.mimeType ?? 'application/octet-stream',
      };
      final initHeaders = initData['headers'];
      if (initHeaders is Map) {
        for (final h in ['Host', 'x-amz-', 'content-']) {
          for (final k in initHeaders.keys) {
            if (k.toLowerCase().startsWith(h) && initHeaders[k] is List) {
              putHeaders[k] = (initHeaders[k] as List).first.toString();
            }
          }
        }
      }

      // Step 2: Upload bytes to presigned URL
      _log.info('put: PUT $uploadUrl');
      await dio.put(
        uploadUrl,
        data: request.dataStream,
        options: Options(headers: putHeaders),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      // Step 3: Confirm
      final confirmBody = <String, dynamic>{
        'r2_key': r2Key,
        'filename': request.fileName,
        'size': request.sizeInBytes,
        'content_type': request.mimeType ?? 'application/octet-stream',
      };
      if (ownerToken != null) {
        confirmBody['owner_token'] = ownerToken;
      }
      _log.info('confirm: POST /api/upload/confirm $confirmBody');
      final confirmResponse = await dio.post(
        '/api/upload/confirm',
        data: confirmBody,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'X-Visitor-Token': visitorToken,
        }),
      );

      final confirmData = confirmResponse.data;
      _log.info('confirm response: ${_trim(jsonEncode(confirmData))}');
      if (confirmData is Map &&
          confirmData['success'] == true &&
          confirmData['file'] is Map) {
        final file = confirmData['file'] as Map;
        final fileUrl = file['raw_url']?.toString() ?? file['url']?.toString();
        if (fileUrl != null) {
          return UploadResult(
            success: true,
            url: fileUrl,
            statusCode: confirmResponse.statusCode,
          );
        }
      }

      final errMsg = confirmData is Map
          ? confirmData['error']?.toString() ?? confirmData.toString()
          : confirmData.toString();
      return UploadResult(
        success: false,
        errorMessage: errMsg,
        statusCode: confirmResponse.statusCode,
      );
    } catch (e, stackTrace) {
      return uploadError(e, stackTrace);
    }
  }

  @override
  UploadResult parseResponse(Response response) {
    // Not used — upload() handles everything
    return uploadError(
      Exception('parseResponse should not be called directly'),
      StackTrace.current,
    );
  }

  String _randomToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return 'vt_${List.generate(32, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  String _trim(String s) {
    if (s.length > 500) return '${s.substring(0, 500)}... (truncated)';
    return s;
  }
}
