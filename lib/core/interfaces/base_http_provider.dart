import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../logging/log.dart';
import '../models/provider_metadata.dart';
import '../models/upload_request.dart';
import '../models/upload_result.dart';
import '../platform/insecure_adapter.dart';
import '../version.dart';

import 'uploader.dart';

abstract class BaseHttpProvider implements BaseUploader {
  late final Log log = Log(runtimeType.toString());

  @override
  bool get isUrlShareOnly => false;

  @override
  bool get supportsMessage => false;

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => const {};

  @override
  String? get proxyUrl => null;

  String get baseUrl;
  String get uploadEndpoint;
  String get fileFormFieldName;

  Map<String, String> get additionalFormFields => const {};

  @override
  List<String> get optionalConfigKeys => const [];

  @override
  List<String> get optionalTextConfigKeys => const [];

  @override
  String? get instanceDescription => null;

  @override
  ProviderMetadata get metadata => const ProviderMetadata();

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
    String? userAgent,
  }) async {
    // Async keyword retained to allow subclasses to override with async operations if needed
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': userAgent ?? 'uppidi-upload/$appVersion',
      },
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
      final prepared = await prepareRequest(config);
      final dio = prepared.dio;
      final cleanConfig = prepared.cleanedConfig;

      final fields = buildFormFields(cleanConfig);
      fields[fileFormFieldName] = buildStreamFile(request);

      final response = await dio.post(
        uploadEndpoint,
        data: FormData.fromMap(fields),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      return parseResponse(response);
    } catch (e, stackTrace) {
      return uploadError(e, stackTrace);
    }
  }

  /// Extracts config, strips internal keys, creates HTTP client.
  /// Providers with no custom config keys pass [Object?] directly.
  Future<PreparedRequest> prepareRequest(Object? config) async {
    final rawConfig =
        config is Map<String, String> ? config : <String, String>{};
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
    return PreparedRequest(
      dio: dio,
      cleanedConfig: cleanConfig,
      allowInsecure: allowInsecure,
      proxyUrl: proxyUrl,
      userAgent: userAgent,
    );
  }

  UploadResult uploadError(Object e, StackTrace stackTrace) {
    log.error('Upload failed: $e', error: e, stackTrace: stackTrace);
    final statusCode = e is DioException ? e.response?.statusCode : null;
    return UploadResult(
      success: false,
      errorMessage: mapException(e),
      rawError: e.toString(),
      statusCode: statusCode,
      stackTrace: stackTrace.toString(),
    );
  }

  UploadResult unhandledError(Response response) {
    log.warn('Unhandled error (returning genericError)');
    return UploadResult(
      success: false,
      errorMessage: 'genericError',
      statusCode: response.statusCode,
    );
  }

  /// Safely parses JSON from a Dio response, handling both String and Map bodies.
  Map<String, dynamic>? parseJsonResponse(Response response) {
    final body = response.data;
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    } else if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return null;
  }

  MultipartFile buildStreamFile(FileUploadRequest request) {
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

  String mapException(Object e) {
    if (e is FormatException) {
      return 'invalidMimeType';
    }
    if (e is FileSystemException) {
      log.error('File system error: ${e.message}', error: e);
      return 'fileSystemError';
    }
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 403 || statusCode == 406 || statusCode == 429) {
        log.warn(
          'HTTP $statusCode — possible User-Agent rejection. '
          'Try setting a custom User-Agent in provider settings.',
        );
      }
      return switch (e.type) {
        DioExceptionType.cancel => 'uploadCancelled',
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          'connectionTimedOut',
        _ => 'genericError',
      };
    }
    return 'genericError';
  }
}

class PreparedRequest {
  final Dio dio;
  final Map<String, String> cleanedConfig;
  final bool allowInsecure;
  final String? proxyUrl;
  final String? userAgent;

  const PreparedRequest({
    required this.dio,
    required this.cleanedConfig,
    required this.allowInsecure,
    this.proxyUrl,
    this.userAgent,
  });
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
