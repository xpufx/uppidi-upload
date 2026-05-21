import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../logging/log.dart';
import '../models/provider_metadata.dart';
import '../models/upload_request.dart';
import '../models/upload_result.dart';
import '../platform/insecure_adapter.dart';
import '../settings_service.dart';

import 'uploader.dart';

abstract class BaseHttpProvider implements BaseUploader {
  late final Log _log = Log(runtimeType.toString());

  String get baseUrl;
  String get uploadEndpoint;
  String get fileFormFieldName;

  Map<String, String> get additionalFormFields => const {};

  @override
  List<String> get optionalConfigKeys => const [];

  @override
  String? get instanceDescription => null;

  @override
  ProviderMetadata get metadata => const ProviderMetadata();

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  }) async {
    // Async keyword retained to allow subclasses to override with async operations if needed
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      // Accept all HTTP status codes — let each provider's parseResponse
      // handle errors. Dio's default throws on non-2xx, which discards
      // the response body (and with it, the provider's error details).
      validateStatus: (_) => true,
    ));

    if (allowInsecureConn) {
      configureInsecureConn(dio);
    }

    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      configureProxy(dio, proxyUrl);
    }

    return dio;
  }

  /// Builds the form fields for the upload request.
  ///
  /// Defaults to [additionalFormFields]. Override to inject values from
  /// [config] (e.g. user-selected expiry). The config map has already had
  /// internal keys (e.g. `_proxy_url`) stripped — it contains only
  /// provider-specific and feature-specific keys like `_expiry`.
  Map<String, dynamic> buildFormFields(Map<String, String> config) {
    return Map<String, dynamic>.from(additionalFormFields);
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config = const {},
  }) async {
    try {
      final allowInsecure = config['_allow_insecure_conn'] == 'true';
      final proxyUrl = config['_proxy_url'];
      final cleanConfig = Map<String, String>.from(config)
        ..remove('_allow_insecure_conn')
        ..remove('_proxy_url');
      final dio = await createHttpClient(cleanConfig,
          allowInsecureConn: allowInsecure, proxyUrl: proxyUrl);

      final fields = buildFormFields(cleanConfig);
      fields[fileFormFieldName] = _buildStreamFile(request);

      // Opt-in debug logging: log request details if enabled
      final settings = SettingsService();
      final debugLogging = await settings.isDebugLoggingEnabled();
      if (debugLogging) {
        _log.info('=== DEBUG UPLOAD REQUEST ===');
        _log.info('Provider: $providerId');
        _log.info('URL: $baseUrl$uploadEndpoint');
        _log.info(
            'File: ${request.fileName} (${request.sizeInBytes} bytes, ${request.mimeType})');
        _log.info('Form fields: $fields');
        _log.info('Additional form fields: $additionalFormFields');
        _log.info('Proxy: $proxyUrl');
        _log.info('Allow insecure: $allowInsecure');
        _log.info('=============================');
      }

      final response = await dio.post(
        uploadEndpoint,
        data: FormData.fromMap(fields),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      // Log response if debug enabled
      if (debugLogging) {
        _log.info('=== DEBUG UPLOAD RESPONSE ===');
        _log.info('Status: ${response.statusCode}');
        _log.info('Headers: ${response.headers}');
        _log.info('Data: ${response.data}');
        _log.info('=============================');
      }

      return parseResponse(response);
    } catch (e, stackTrace) {
      _log.error('Upload failed: $e', error: e, stackTrace: stackTrace);
      // statusCode is only available for DioExceptions (which have associated HTTP responses); non-Dio exceptions have no HTTP status code, so default to null
      final statusCode = e is DioException ? e.response?.statusCode : null;
      return UploadResult(
        success: false,
        errorMessage: _mapException(e),
        rawError: e.toString(),
        statusCode: statusCode,
        stackTrace: stackTrace.toString(),
      );
    }
  }

  MultipartFile _buildStreamFile(FileUploadRequest request) {
    return MultipartFile.fromStream(
      () => request.dataStream,
      request.sizeInBytes,
      filename: request.fileName,
      contentType: request.mimeType != null
          ? DioMediaType.parse(request.mimeType!)
          : null,
    );
  }

  UploadResult parseResponse(Response response);

  String _mapException(Object e) {
    if (e is FormatException) {
      return 'invalidMimeType';
    }
    if (e is FileSystemException) {
      _log.error('File system error: ${e.message}', error: e);
      return 'fileSystemError';
    }
    if (e is DioException) {
      return switch (e.type) {
        DioExceptionType.cancel => 'uploadCancelled',
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          'errorConnectionFailed',
        _ => 'genericError',
      };
    }
    return 'genericError';
  }
}

/// Apply proxy configuration to a Dio instance.
/// Supports HTTP/HTTPS proxy (http://host:port or https://host:port).
/// SOCKS5 proxies require a third-party adapter — not yet implemented.
void configureProxy(Dio dio, String proxyUrl) {
  final trimmed = proxyUrl.trim();
  if (trimmed.isEmpty) return;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) return;

  // HTTP/HTTPS proxy — configure via underlying HttpClient
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (url) => 'PROXY ${uri.host}:${uri.port}';
      return client;
    },
  );
}
