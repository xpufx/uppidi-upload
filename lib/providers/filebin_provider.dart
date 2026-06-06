import 'dart:math';

import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import 'filebin_config.dart';

class FilebinProvider extends BaseHttpProvider {
  @override
  String get providerId => 'filebin';

  @override
  String get providerName => 'Filebin.net';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

  @override
  String get baseUrl => 'https://filebin.net';

  @override
  String get uploadEndpoint => '';

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
      final cfg = config is FilebinConfig ? config : const FilebinConfig();
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

      final bin = _randomBin();
      final url = '/$bin/${request.fileName}';

      final response = await dio.post(
        url,
        data: request.dataStream,
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': request.sizeInBytes.toString(),
          },
        ),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      return parseResponse(response);
    } catch (e, stackTrace) {
      return uploadError(e, stackTrace);
    }
  }

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode == 201 && response.data is Map) {
      final data = response.data as Map;
      final binId = data['bin']?['id']?.toString();
      final fileName = data['file']?['filename']?.toString();
      if (binId != null && fileName != null) {
        return UploadResult(
          success: true,
          url: 'https://filebin.net/$binId/$fileName',
          statusCode: response.statusCode,
        );
      }
    }
    return UploadResult(
      success: false,
      errorMessage: 'genericError',
      statusCode: response.statusCode,
    );
  }

  String _randomBin() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(15, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
