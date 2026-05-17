import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uppidi_upload/core/platform/insecure_adapter.dart';

void main() {
  group('Insecure connection — functional test', () {
    late HttpServer secureServer;
    late int serverPort;
    late Directory tempDir;
    late File certFile;
    late File keyFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('insecure_test_');
      certFile = File('${tempDir.path}/cert.pem');
      keyFile = File('${tempDir.path}/key.pem');

      // Write the self-signed cert and key to temp files
      await certFile.writeAsString(_certPem);
      await keyFile.writeAsString(_keyPem);

      final securityContext = SecurityContext()
        ..useCertificateChain(certFile.path)
        ..usePrivateKey(keyFile.path);

      secureServer = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        securityContext,
      );
      serverPort = secureServer.port;
      secureServer.listen((HttpRequest request) {
        request.response.statusCode = 200;
        request.response.headers.set('content-length', '2');
        request.response.write('OK');
        request.response.close();
      });
    });

    tearDown(() async {
      await secureServer.close(force: true);
      await tempDir.delete(recursive: true);
    });

    test('request WITHOUT insecure config FAILS on self-signed cert', () async {
      final serverUrl = 'https://127.0.0.1:$serverPort';
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      try {
        await dio.get('/test');
        fail('Expected a DioException (handshake error) but got success');
      } on DioException catch (e) {
        // Should be a connection error due to bad certificate
        expect(
            e.type,
            anyOf(
              DioExceptionType.connectionError,
              DioExceptionType.connectionTimeout,
              DioExceptionType.unknown,
            ));
      }
    });

    test('request WITH insecure config SUCCEEDS on self-signed cert', () async {
      final serverUrl = 'https://127.0.0.1:$serverPort';
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      configureInsecureConn(dio);

      final response = await dio.get('/test');
      expect(response.statusCode, 200);
      expect(response.data, 'OK');
    });

    test(
        'default Dio adapter rejects self-signed cert, insecure adapter accepts',
        () async {
      final serverUrl = 'https://127.0.0.1:$serverPort';

      // Default adapter should reject self-signed cert
      final dioDefault = Dio(BaseOptions(baseUrl: serverUrl));
      await expectLater(
        () => dioDefault.get('/test'),
        throwsA(isA<DioException>()),
      );

      // Same adapter after configureInsecureConn should accept
      configureInsecureConn(dioDefault);
      final response = await dioDefault.get('/test');
      expect(response.statusCode, 200);
    });

    test('configureInsecureConn replaces the adapter', () async {
      final dio = Dio();
      final originalAdapter = dio.httpClientAdapter;

      configureInsecureConn(dio);

      expect(dio.httpClientAdapter, isNot(same(originalAdapter)));
      expect(dio.httpClientAdapter, isA<IOHttpClientAdapter>());
    });
  });
}

/// Self-signed certificate for localhost (generated with openssl).
/// CN=localhost, valid for 1 year.
const String _certPem = '''
-----BEGIN CERTIFICATE-----
MIIDCTCCAfGgAwIBAgIUJ0OP8HFPhcoHtiX7Wo460eCiBJMwDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MB4XDTI2MDUxMDA4MjE0NFoXDTI3MDUx
MDA4MjE0NFowFDESMBAGA1UEAwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEA1TO4ngw6zPXVm8fAvEwcfbxqwR3GWpUrfZE2V9ZcS4cr
dfW9CQmOWXCqfjzO73Pd9vowBB853OnlS87yfH2gNgrcMA1MdrBWat69T9k3xyrd
TdTmdvwXjhfpVAhBMZF35SRHG5x261+NEe/+cziGZf6OqhkP38peiD0QCOMN/rgJ
ysdS6P+NWHzYNTy/o++Y3oiucMp9Qp5xHc8d057jbv9JTxx/tJgUnIqCJClOeCOA
xAqlcisTJ/yz1JkhfGuCbuyW8cok3WKW9zd5RU1QtC8a3F9SopGqWEhNtDB0NM3I
cRWNt8wDb+f70MRfhou/GCosLXweko7VRn68NgXa0QIDAQABo1MwUTAdBgNVHQ4E
FgQUdJ0nBFlZzt/+edMTvrkY3yneeD4wHwYDVR0jBBgwFoAUdJ0nBFlZzt/+edMT
vrkY3yneeD4wDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAUFUc
ZJQwLM6cb05pN3f8uHvfShkqBygzJ/FBa5TSc0E8gaMSzwVWLDxMZB2/VwzK3Kzd
ShWNrjIuKqddFXHAX5xkUU95Rmh1A02TolNKiJlzjBsZXupvIbCNTHkCwpJa0DOG
KEXGHyksl1JeZtamQ1v4nGULLFMaYyiksU16dgOvLuMU0DmmNc7ekFO0qpXVyod4
RFcBzBqRLPz6E2h0y3KH5L25ATtgKY4oAo7ULZM+zuDmk5a94xmk72ip+cfEhs/I
PRC4drvgBdrWFY20zExyyq8QdSpi9TIDwomA4VFm5mxJlsBXfA9Txs+Mzy4obZH+
aq37mVkt4RYi80/SuQ==
-----END CERTIFICATE-----
''';

/// Corresponding private key.
const String _keyPem = '''
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDVM7ieDDrM9dWb
x8C8TBx9vGrBHcZalSt9kTZX1lxLhyt19b0JCY5ZcKp+PM7vc932+jAEHznc6eVL
zvJ8faA2CtwwDUx2sFZq3r1P2TfHKt1N1OZ2/BeOF+lUCEExkXflJEcbnHbrX40R
7/5zOIZl/o6qGQ/fyl6IPRAI4w3+uAnKx1Lo/41YfNg1PL+j75jeiK5wyn1CnnEd
zx3TnuNu/0lPHH+0mBScioIkKU54I4DECqVyKxMn/LPUmSF8a4Ju7JbxyiTdYpb3
N3lFTVC0LxrcX1KikapYSE20MHQ0zchxFY23zANv5/vQxF+Gi78YKiwtfB6SjtVG
frw2BdrRAgMBAAECggEAASXl2bM4jwlh2ZSYe2SwU8lm2VxdYl58Q5Eh6RSTHnSY
+mnucMG3t2nHMtlr+deDYff6uAL2ok0y7WOs/Zhr+1Tqo52Z6rR/YQe+ODnz6XAk
wFPXQkIp2rUfp598J/xGPrPuNOSOS8bFCswvVnp+8SyoowGlV4l07qhGUYeIRNwn
uBkn9sVhZiz8X9rfYFrIf3dKWzAnzvO+4MRvJLO+8Zmh27x4xD0Z4AiihvpFVNyw
GiVpryTTez1gGtdd3FKQFMFkZvC7uui0pyrOJJ4KZhJE/SD5EOBugj/neduPaEk4
2FBmO6O2HzEv2r6akaVCzQTOmjxSm2KAlnUmONsDYwKBgQD379Q1fX9uaGXVPKgZ
kJlabbFMgO+UVsK2SZozvecMsNzQwMur+2QisEaaWYsC2ZugOFaFm0OfOei/Gh5x
jgonfDwi+NHn5ohcOBBvLf1+di/af8fmJxOWCnavjmd+atgpjjGtaMDz6+LQdH5r
VC6zwMEi46HSekTQkGVMtClCwwKBgQDcIrYiemlv2o5OdRnQDrk5sJ0wHcP9Ojyf
sFy7agT9cliLcI1AmeNp4b1L0Usn56OKoaxEk7kUj/M1D5dpktDG4IArxRObmcFg
DYcmXbBvbnpiPW0ivnNH96E2uwy9UV+nfhjxU/GgYQx2WIgHmiYrRkjihSx0yREX
0aNsv0dq2wKBgQDhG/gxhLthlBn5THRXmckSqIuUqXBc35U0ComeNuqDxEUIqDOD
9+DH+gJwe6JSOR8qjlxIPFteQybF88H2Wf9wMEUtf3qdsdrW1/Rb7Ya9/jKekOv/
VDVdQizWYlYnGn0e5cLG7lhaXy51E4AAlNM+U2FH+yNexbKbJq9CwETCHwKBgD1f
8CfsuTjWVpbJT0kS0dGjzC9+HQadFgnvwer+xCVlnApEdx1rylva9EwPLkUR8CbW
rJDyHsf82nIQxsZIiKzqKtIJQE5BsAh3vRaVSHvI8ZYyShtFvh5yjCAWRpcB+QlZ
vtqJ7PQqGq9kP4jfEYU/M1L0jlCBPqLFcCsBqYfBAoGBANrTUP2bOmti7bvDHaI8
ESKshF1n8wYdmXIw53smwNbBmD8FIqsTAM3Vh40dgtT+EbvD581/Cprryz9ub8Es
Pst9q/hVtOsE3dZdfcOP2WsnwZMWd1kO0uvoI8HilKiFj0qW7/zJld6oy6WtCBq3
+8YqD+A2OhyAr9RKDxnBQMf9
-----END PRIVATE KEY-----
''';
