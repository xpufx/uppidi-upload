#!/usr/bin/env dart
import 'dart:io';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  stderr.writeln('Test server running at http://${server.address.host}:${server.port}');

  await for (final request in server) {
    if (request.method == 'POST' && request.uri.path == '/user/api.php') {
      await request.cast<List<int>>().length;
      await Future.delayed(Duration(seconds: 2));

      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.text
        ..write('https://files.catbox.moe/test-${DateTime.now().millisecondsSinceEpoch}.jpg');
      await request.response.close();
      stderr.writeln('Upload request received -> returned fake URL');
    } else {
      request.response
        ..statusCode = 404
        ..write('Not found');
      await request.response.close();
    }
  }
}
