import 'dart:async';
import 'package:dio/dio.dart';

import '../models/upload_request.dart';
import '../models/upload_result.dart';

typedef UploadProgressCallback = void Function(int sent, int total);

abstract class BaseUploader {
  String get providerId;
  String get providerName;
  bool get supportsWeb;
  List<String> get requiredConfigKeys;
  Map<String, String> get configLabels;
  String? get proxyUrl;

  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
  });

  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
  });
}
