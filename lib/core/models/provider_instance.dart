import 'package:dio/dio.dart';

import '../interfaces/uploader.dart';
import 'provider_metadata.dart';
import 'upload_request.dart';
import 'upload_result.dart';

/// Wraps a [BaseUploader] with an instance identity so the same provider
/// type (e.g. Telegram) can appear multiple times with different
/// credentials. Each instance has its own [instanceId] and [instanceName].
///
/// The [providerId] is derived as `{base.providerId}__{instanceId}` so that
/// config storage keys are naturally scoped to the instance.
class ProviderInstance implements BaseUploader {
  final BaseUploader _base;
  final String instanceId;
  final String instanceName;

  const ProviderInstance(this._base, this.instanceId, this.instanceName);

  @override
  String get providerId => '${_base.providerId}__$instanceId';

  @override
  String get providerName => instanceName;

  /// Display name including the base provider type, e.g. "Telegram (Work Bot)".
  String get displayName => '${_base.providerName} ($instanceName)';

  @override
  bool get supportsWeb => _base.supportsWeb;

  @override
  List<String> get requiredConfigKeys => _base.requiredConfigKeys;

  @override
  List<String> get optionalConfigKeys => _base.optionalConfigKeys;

  @override
  Map<String, String> get configLabels => _base.configLabels;

  @override
  String? get proxyUrl => _base.proxyUrl;

  @override
  ProviderMetadata get metadata => _base.metadata;

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  }) =>
      _base.createHttpClient(
        config,
        allowInsecureConn: allowInsecureConn,
        proxyUrl: proxyUrl,
      );

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config = const {},
  }) =>
      _base.upload(
        request,
        onProgress: onProgress,
        cancelToken: cancelToken,
        config: config,
      );
}
