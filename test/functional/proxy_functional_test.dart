import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uppidi_upload/core/interfaces/base_http_provider.dart';
import 'package:uppidi_upload/core/platform/insecure_adapter.dart';

void main() {
  group('Proxy — functional test', () {
    late HttpServer proxyServer;
    late int proxyPort;
    final receivedRequests = <HttpRequest>[];

    setUp(() async {
      receivedRequests.clear();
      proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      proxyPort = proxyServer.port;
      proxyServer.listen((HttpRequest request) {
        receivedRequests.add(request);
        // Respond with success — we don't need to forward anywhere
        request.response.statusCode = 200;
        request.response.headers.set('content-length', '0');
        request.response.close();
      });
    });

    tearDown(() async {
      await proxyServer.close(force: true);
    });

    test('Dio GET request is routed through the configured proxy', () async {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://does-not-exist.example',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      configureProxy(dio, 'http://127.0.0.1:$proxyPort');

      // Make a GET request — it should go through our proxy
      await dio.get('/test-path');

      // Verify the proxy received exactly one request
      expect(receivedRequests, hasLength(1));

      final req = receivedRequests.first;
      // The full URI should include the original target
      expect(req.uri.host, 'does-not-exist.example');
      expect(req.uri.path, '/test-path');
      expect(req.method, 'GET');
    });

    test('Dio POST request is routed through the configured proxy', () async {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://target.example',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      configureProxy(dio, 'http://127.0.0.1:$proxyPort');

      await dio.post('/submit', data: {'key': 'value'});

      expect(receivedRequests, hasLength(1));
      expect(receivedRequests.first.method, 'POST');
      expect(receivedRequests.first.uri.path, '/submit');
    });

    test('requests are NOT routed through proxy when proxy is NOT configured',
        () async {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://127.0.0.1:$proxyPort',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      // Do NOT call configureProxy

      // This request goes DIRECTLY to the server (which is our "proxy" acting
      // as a plain server here)
      await dio.get('/direct');

      expect(receivedRequests, hasLength(1));
      // When connecting directly, the URI path is just '/direct'
      // (the target is resolved to the server's address)
      expect(receivedRequests.first.uri.path, '/direct');
    });
  });

  group('Proxy — combined with insecure connections', () {
    late HttpServer proxyServer;
    late int proxyPort;
    final receivedRequests = <HttpRequest>[];

    setUp(() async {
      receivedRequests.clear();
      proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      proxyPort = proxyServer.port;
      proxyServer.listen((HttpRequest request) {
        receivedRequests.add(request);
        request.response.statusCode = 200;
        request.response.headers.set('content-length', '0');
        request.response.close();
      });
    });

    tearDown(() async {
      await proxyServer.close(force: true);
    });

    test('proxy still works when both proxy and insecure options are provided',
        () async {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://target.example',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      // Simulate what BaseHttpProvider.createHttpClient does
      configureInsecureConn(dio);
      configureProxy(dio, 'http://127.0.0.1:$proxyPort');

      await dio.get('/test');

      expect(receivedRequests, hasLength(1));
      expect(receivedRequests.first.uri.path, '/test');
    });
  });
}
