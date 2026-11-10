import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';
import 'package:test/test.dart';

/// A site linking files whose path holds encoded slashes (`%2F`), served for
/// any path.
Future<HttpServer> _startSite() async {
  final server = await httpServerFactoryMemory.bind(
    InternetAddress.anyIPv4,
    portDynamic,
  );
  server.listen((request) async {
    final response = request.response;
    if (request.uri.path == '/') {
      response.headers.set('content-type', 'text/html');
      response.add(
        Uint8List.fromList(
          utf8.encode(
            '<a href="/..%2F..%2F..%2Fescape.html">page</a>'
            '<img src="/a/..%2F..%2F..%2F..%2Fescape.png">'
            '<img src="/img/logo.png">',
          ),
        ),
      );
    } else {
      response.headers.set('content-type', 'image/png');
      response.add(Uint8List.fromList([1, 2, 3]));
    }
    await response.close();
  });
  return server;
}

void main() {
  late HttpServer server;
  late FileSystem fs;
  late Directory out;

  setUp(() async {
    server = await _startSite();
    fs = newFileSystemMemory();
    out = fs.directory('/home/user/out/site');
    await out.create(recursive: true);
  });

  tearDown(() async {
    await server.close();
  });

  Future<List<String>> allFiles() async => [
    await for (final entity in fs.directory('/').list(recursive: true))
      if (entity is File) entity.path,
  ]..sort();

  test('webScrapperDefaultLocalPath encoded slash', () {
    final path = webScrapperDefaultLocalPath(
      Uri.parse('https://example.com/..%2F..%2Fescape.txt'),
    );
    expect(path.split('/'), isNot(contains('..')));
    expect(path, 'example.com/.._.._escape.txt');
  });

  test('encoded slashes stay in the output directory', () async {
    final result = await WebScrapper(
      startUris: [httpServerGetUri(server)],
      outDirectory: out,
      httpClientFactory: httpClientFactoryMemory,
    ).run();
    expect(result.failed, isEmpty);
    final files = await allFiles();
    expect(files, hasLength(4));
    for (final file in files) {
      expect(file, startsWith('/home/user/out/site/'));
    }
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('localPath leaving the output directory fails', () async {
    final result = await WebScrapper(
      startUris: [httpServerGetUri(server)],
      outDirectory: out,
      httpClientFactory: httpClientFactoryMemory,
      options: WebScrapperOptions(
        localPath: (uri) => uri.path == '/img/logo.png'
            ? '../../logo.png'
            : webScrapperDefaultLocalPath(uri),
      ),
    ).run();
    expect(result.failed.map((entry) => entry.uri.path), ['/img/logo.png']);
    final files = await allFiles();
    for (final file in files) {
      expect(file, startsWith('/home/user/out/site/'));
    }
  }, timeout: const Timeout(Duration(seconds: 20)));
}
