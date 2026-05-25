import 'package:dio/dio.dart';

import '../models/provider_metadata.dart';
import '../models/upload_request.dart';
import '../models/upload_result.dart';

typedef UploadProgressCallback = void Function(int sent, int total);

abstract class BaseUploader {
  String get providerId;
  String get providerName;
  bool get supportsWeb;

  /// True for relay-only providers (e.g. IRC via Matterbridge) that
  /// can't host files and only forward URLs.
  bool get isUrlShareOnly => false;
  List<String> get requiredConfigKeys;

  /// Optional boolean config keys (rendered as checkboxes in the config
  /// dialog). Each key should have a corresponding label in [configLabels].
  List<String> get optionalConfigKeys => const [];

  /// Optional text config keys (rendered as text fields without validators).
  /// Unlike [requiredConfigKeys], these can be left empty and don't affect
  /// the "is configured" check.
  List<String> get optionalTextConfigKeys => const [];
  Map<String, String> get configLabels;
  String? get proxyUrl;

  /// Optional short description shown in the "Add instance" dialog, e.g.
  /// "Telegram Bot API — send files to any chat". Only providers with a
  /// non-null description appear as addable instance types.
  String? get instanceDescription => null;

  ProviderMetadata get metadata;

  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  });

  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config,
  });
}
