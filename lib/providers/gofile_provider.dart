import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/platform/insecure_adapter.dart';
import 'gofile_config.dart';

class GoFileProvider extends BaseHttpProvider {
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: null,
        expiryInfo: '10 days without download (free tier)',
        supportsDirectLink: false,
      );

  @override
  String get providerId => 'gofile';

  @override
  String get providerName => 'GoFile';

  @override
  bool get supportsWeb => true;

  @override
  String get baseUrl => 'https://api.gofile.io';

  @override
  String get uploadEndpoint => '/servers';

  @override
  String get fileFormFieldName => 'file';

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Object? config,
  }) async {
    try {
      final gofileConfig =
          config is GoFileConfig ? config : const GoFileConfig();
      final prepared = await prepareRequest(gofileConfig.data);
      final dio = prepared.dio;
      final allowInsecure = prepared.allowInsecure;
      final proxyUrlValue = prepared.proxyUrl;

      final serverResponse = await dio.get('/servers');

      if (serverResponse.statusCode != 200 ||
          serverResponse.data is! Map<String, dynamic>) {
        return unhandledError(serverResponse);
      }

      final serverData = serverResponse.data as Map<String, dynamic>;
      if (serverData['status'] != 'ok') {
        return unhandledError(serverResponse);
      }

      final servers = serverData['data']['servers'] as List;
      if (servers.isEmpty) {
        return unhandledError(serverResponse);
      }

      final serverName = servers[0]['name'] as String;
      final uploadUrl = 'https://$serverName.gofile.io/uploadFile';

      final fields = <String, dynamic>{
        fileFormFieldName: MultipartFile.fromStream(
          () => request.dataStream,
          request.sizeInBytes,
          filename: request.fileName,
          contentType: request.mimeType != null
              ? DioMediaType.parse(request.mimeType!)
              : null,
        ),
      };

      final uploadDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (_) => true,
        headers: {
          'User-Agent': prepared.dio.options.headers['User-Agent'] ??
              'uppidi-upload',
        },
      ));

      if (allowInsecure) {
        configureInsecureConn(uploadDio);
      }

      if (proxyUrlValue != null && proxyUrlValue.isNotEmpty) {
        configureProxy(uploadDio, proxyUrlValue);
      }

      final response = await uploadDio.post(
        uploadUrl,
        data: FormData.fromMap(fields),
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
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      if (data['status'] == 'ok' && data['data'] is Map) {
        final resultData = data['data'] as Map<String, dynamic>;
        final downloadPage = resultData['downloadPage'] as String?;
        if (downloadPage != null && downloadPage.isNotEmpty) {
          return UploadResult(
            success: true,
            url: downloadPage,
            statusCode: response.statusCode,
          );
        }
      }
    }

    return unhandledError(response);
  }
}
