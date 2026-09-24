import 'dart:typed_data';

import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';
import 'package:test/test.dart';

import 'src/test_site.dart';

void main() {
  late TestSite site;
  late TestSite external;
  late FileSystem fs;
  late Directory out;
  late String host; // local directory of site
  late String externalHost;

  setUp(() async {
    external = TestSite({});
    await external.start();
    site = TestSite({});
    await site.start();
    final ext = external.uri;
    site.files.addAll({
      '/': TestFile.html('''
<html><head>
<link rel="stylesheet" href="style.css">
<link rel="icon" href="/favicon.ico">
<link rel="preconnect" href="$ext">
<script type="importmap">{"imports": {"lib": "./vendor/lib.js"}}</script>
<script type="module" src="src/app.js"></script>
</head><body>
<a href="about">About</a>
<a href="sub/">Sub</a>
<a href="#top">Top</a>
<a href="mailto:me@example.com">Mail</a>
<a href="${ext}external.html">External page</a>
<img src="${ext}external.png">
<img srcset="img/a.png 1x, img/a2.png 2x">
<div style="background: url('img/bg.jpg')"></div>
</body></html>
'''),
      '/style.css': TestFile(
        '@import "theme.css";\n'
        'body { background: url(img/body.png) }\n'
        '@font-face { src: url("fonts/f.woff2") format("woff2"); }',
        contentType: 'text/css',
      ),
      '/theme.css': TestFile('.x {}', contentType: 'text/css'),
      '/src/app.js': TestFile(
        "import { a } from './util.js';\n"
        "import lib from 'lib';\n"
        "const manifest = 'media.json';\n"
        "fetch('data/missing.json');\n",
        contentType: 'text/javascript',
      ),
      '/src/util.js': TestFile(
        'export const a = 1;',
        contentType: 'text/javascript',
      ),
      '/vendor/lib.js': TestFile(
        'export default {};',
        contentType: 'text/javascript',
      ),
      '/media.json': TestFile(
        '{"media": [{"src": "media/v1.mp4", "poster": "posters/v1.jpg"}]}',
        contentType: 'application/json',
      ),
      '/media/v1.mp4': TestFile(
        Uint8List.fromList([1, 2, 3]),
        contentType: 'video/mp4',
      ),
      '/posters/v1.jpg': TestFile(Uint8List.fromList([4, 5])),
      '/favicon.ico': TestFile(Uint8List.fromList([6])),
      '/img/a.png': TestFile(Uint8List.fromList([7])),
      '/img/a2.png': TestFile(Uint8List.fromList([8])),
      '/img/bg.jpg': TestFile(Uint8List.fromList([9])),
      '/img/body.png': TestFile(Uint8List.fromList([10])),
      '/fonts/f.woff2': TestFile(Uint8List.fromList([11])),
      '/about': TestFile.html(
        '<a href="sub/page2.html">page2</a><a href="missing.html">missing</a>',
      ),
      '/sub/': TestFile.html('<a href="../">home</a><a href="deep/">deep</a>'),
      '/sub/deep/': TestFile.html('<p>deep</p>'),
      '/sub/page2.html': TestFile.html('<p>page2</p>'),
    });
    external.files.addAll({
      '/external.html': TestFile.html(
        '<img src="ext_img.png"><a href="other.html">other</a>'
        '<a href="${site.uri}sub/">back</a>',
      ),
      '/external.png': TestFile(Uint8List.fromList([12])),
      '/ext_img.png': TestFile(Uint8List.fromList([13])),
      '/other.html': TestFile.html('<p>other</p>'),
    });
    fs = newFileSystemMemory();
    out = fs.directory('/out');
    host = webScrapperDefaultLocalPath(site.uri).split('/').first;
    externalHost = webScrapperDefaultLocalPath(external.uri).split('/').first;
  });

  tearDown(() async {
    await site.close();
    await external.close();
  });

  Future<WebScrapperResult> scrap([
    WebScrapperOptions? options,
    Directory? outDirectory,
  ]) => WebScrapper(
    startUris: [site.uri],
    outDirectory: outDirectory ?? out,
    httpClientFactory: httpClientFactoryMemory,
    options: options,
  ).run();

  Future<List<String>> savedFiles() async {
    final files = <String>[];
    if (!await out.exists()) {
      return files;
    }
    await for (final entity in out.list(recursive: true)) {
      if (entity is File) {
        files.add(fs.path.relative(entity.path, from: out.path));
      }
    }
    return files..sort();
  }

  List<String> sitePaths(Iterable<String> paths) =>
      paths.map((path) => '$host/$path').toList();

  final defaultSitePaths = [
    'about.html',
    'favicon.ico',
    'fonts/f.woff2',
    'img/a.png',
    'img/a2.png',
    'img/bg.jpg',
    'img/body.png',
    'index.html',
    'src/app.js',
    'src/util.js',
    'style.css',
    'sub/deep/index.html',
    'sub/index.html',
    'sub/page2.html',
    'theme.css',
    'vendor/lib.js',
  ];

  test('default', () async {
    final result = await scrap();
    expect(await savedFiles(), sitePaths(defaultSitePaths));
    expect(external.requests, isEmpty);
    expect(result.failed.map((entry) => entry.uri.path), ['/missing.html']);
    final missing = result.failed.single;
    expect(missing.statusCode, httpStatusCodeNotFound);
    expect(missing.referrer, site.uri.resolve('about'));
    expect(result.downloaded.length, defaultSitePaths.length);
    // Each url fetched once
    expect(site.requests.length, site.requests.toSet().length);
    expect(
      await fs.file('/out/$host/img/a.png').readAsBytes(),
      Uint8List.fromList([7]),
    );
  });

  test('depth', () async {
    await scrap(const WebScrapperOptions(maxDepth: 0));
    expect(
      await savedFiles(),
      sitePaths(
        defaultSitePaths.where(
          (path) => !path.startsWith('sub/') && path != 'about.html',
        ),
      ),
    );
    await out.delete(recursive: true);
    await scrap(const WebScrapperOptions(maxDepth: 1));
    expect(
      await savedFiles(),
      sitePaths(
        defaultSitePaths.where(
          (path) => path != 'sub/deep/index.html' && path != 'sub/page2.html',
        ),
      ),
    );
  });

  test('scanStrings', () async {
    final result = await scrap(const WebScrapperOptions(scanStrings: true));
    expect(
      await savedFiles(),
      sitePaths(
        [...defaultSitePaths, 'media.json', 'media/v1.mp4', 'posters/v1.jpg']
          ..sort(),
      ),
    );
    expect(result.failed.map((entry) => entry.uri.path).toSet(), {
      '/missing.html',
      '/data/missing.json',
    });
  });

  test('followExternalResources', () async {
    await scrap(const WebScrapperOptions(followExternalResources: true));
    expect(
      await savedFiles(),
      ['$externalHost/external.png', ...sitePaths(defaultSitePaths)]..sort(),
    );
    expect(external.requests, ['/external.png']);
  });

  test('followExternalLinks', () async {
    await scrap(const WebScrapperOptions(followExternalLinks: true));
    // One hop, no external resources
    expect(external.requests, ['/external.html']);
    external.requests.clear();
    await out.delete(recursive: true);
    await scrap(
      const WebScrapperOptions(
        followExternalLinks: true,
        followExternalResources: true,
      ),
    );
    expect(external.requests.toSet(), {
      '/external.html',
      '/external.png',
      '/ext_img.png',
    });
  });

  test('cache and force', () async {
    await scrap();
    final requestCount = site.requests.length;
    final result = await scrap();
    // Only the missing page is requested again
    expect(site.requests.sublist(requestCount), ['/missing.html']);
    expect(result.cached.length, defaultSitePaths.length);
    expect(await savedFiles(), sitePaths(defaultSitePaths));

    site.requests.clear();
    final forced = await scrap(const WebScrapperOptions(force: true));
    expect(forced.downloaded.length, defaultSitePaths.length);
    expect(site.requests.length, defaultSitePaths.length + 1);
  });

  test('filter and hosts', () async {
    await scrap(
      WebScrapperOptions(
        filter: (uri) => !uri.path.startsWith('/sub/') && uri.path != '/about',
      ),
    );
    expect(
      await savedFiles(),
      sitePaths(
        defaultSitePaths.where(
          (path) => !path.startsWith('sub/') && path != 'about.html',
        ),
      ),
    );
    // External host declared as part of the site: its pages are followed.
    await scrap(
      WebScrapperOptions(
        hosts: ['${external.uri.host}:${external.uri.port}'],
        maxDepth: 1,
      ),
    );
    // other.html is at depth 2.
    expect(external.requests.toSet(), {
      '/external.html',
      '/external.png',
      '/ext_img.png',
    });
  });

  test('maxFiles', () async {
    final result = await scrap(const WebScrapperOptions(maxFiles: 3));
    expect(result.entries.length, 3);
    expect(site.requests.length, 3);
  });

  test('onContent and onEntry', () async {
    final contents = <String, WebScrapperContent>{};
    final entries = <WebScrapperEntry>[];
    final result = await scrap(
      WebScrapperOptions(
        maxDepth: 0,
        onEntry: entries.add,
        onContent: (content) async {
          contents[content.uri.path] = content;
          if (content.uri == site.uri) {
            // custom link added, stylesheet removed.
            content.links
              ..removeWhere((link) => link.uri.path.endsWith('.css'))
              // relative, resolved against the content url
              ..add(WebScrapperLink(Uri.parse('media.json')));
          }
        },
      ),
    );
    expect(entries, result.entries);
    final index = contents['/']!;
    expect(index.document!.body.querySelector('a')!.text, 'About');
    expect(index.format, WebScrapperContentFormat.html);
    expect(index.contentType, 'text/html');
    expect(index.localPath, '$host/index.html');
    expect(index.fromCache, isFalse);
    expect(contents.keys, isNot(contains('/style.css')));
    expect(contents['/media.json']!.format, WebScrapperContentFormat.json);
    expect(contents['/media.json']!.text, contains('v1.mp4'));
    final png = contents['/img/a.png']!;
    expect(png.text, isNull);
    expect(await png.readBytes(), Uint8List.fromList([7]));
    expect(png.referrer, site.uri);
  });

  test('no output directory', () async {
    final bytes = <String, Uint8List>{};
    final scrapper = WebScrapper(
      startUris: [site.uri.resolve('sub/')],
      httpClientFactory: httpClientFactoryMemory,
      options: WebScrapperOptions(
        onContent: (content) async {
          expect(content.file, isNull);
          bytes[content.uri.path] = await content.readBytes();
        },
      ),
    );
    final result = await scrapper.run();
    expect(result.failed, hasLength(1)); // missing.html
    expect(bytes['/img/a.png'], Uint8List.fromList([7]));
    expect(bytes.keys, contains('/sub/deep/'));
  });

  test('content handler error', () async {
    final result = await scrap(
      WebScrapperOptions(
        onContent: (content) {
          if (content.uri.path == '/about') {
            throw StateError('parse error');
          }
        },
      ),
    );
    final failed = result.failed.firstWhere(
      (entry) => entry.uri.path == '/about',
    );
    expect(failed.error, isA<StateError>());
    // about links not followed
    expect(site.requests, isNot(contains('/sub/page2.html')));
  });

  test('invalid start url', () {
    expect(
      () => WebScrapper(startUris: [Uri.parse('ftp://example.com')]),
      throwsArgumentError,
    );
    expect(() => WebScrapper(startUris: []), throwsArgumentError);
  });
}
