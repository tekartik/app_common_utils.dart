import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_app_http/app_http.dart';

/// A file served by a [TestSite].
class TestFile {
  final String? contentType;
  final Object body;

  TestFile(this.body, {this.contentType});

  TestFile.html(String html) : this(html, contentType: 'text/html');
}

/// In memory http site serving [files] (path to file), counting requests.
class TestSite {
  final Map<String, TestFile> files;
  final requests = <String>[];
  late HttpServer _server;

  TestSite(this.files);

  Uri get uri => httpServerGetUri(_server);

  /// Resolve a path against the site root.
  String url(String path) => uri.resolve(path).toString();

  Future<void> start() async {
    _server = await httpServerFactoryMemory.bind(
      InternetAddress.anyIPv4,
      portDynamic,
    );
    _server.listen((request) async {
      final path = request.uri.path.isEmpty ? '/' : request.uri.path;
      requests.add(path);
      final response = request.response;
      final file = files[path];
      if (file == null) {
        response.statusCode = httpStatusCodeNotFound;
        response.write('not found');
      } else {
        final contentType = file.contentType;
        if (contentType != null) {
          response.headers.set('content-type', contentType);
        }
        final body = file.body;
        response.add(
          body is String
              ? Uint8List.fromList(utf8.encode(body))
              : body as Uint8List,
        );
      }
      await response.close();
    });
  }

  Future<void> close() => _server.close();
}
