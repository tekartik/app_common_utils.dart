@TestOn('vm')
library;

import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_web_scrapper/app_web_scrapper_cli.dart';
import 'package:test/test.dart';

import 'src/test_site.dart';

void main() {
  late TestSite site;
  late FileSystem fs;
  late StringBuffer out;
  late StringBuffer err;
  late String host;

  setUp(() async {
    site = TestSite({
      '/': TestFile.html(
        '<link rel="stylesheet" href="style.css">'
        '<a href="page.html">page</a><a href="skip/">skip</a>'
        '<a href="broken.html">broken</a>',
      ),
      '/style.css': TestFile('body {}', contentType: 'text/css'),
      '/page.html': TestFile.html('<a href="deep.html">deep</a>'),
      '/deep.html': TestFile.html('<p>deep</p>'),
      '/skip/': TestFile.html('<p>skip</p>'),
    });
    await site.start();
    fs = newFileSystemMemory();
    out = StringBuffer();
    err = StringBuffer();
    host = webScrapperDefaultLocalPath(site.uri).split('/').first;
  });

  tearDown(() => site.close());

  Future<int> run(List<String> arguments) => WebScrapperCli(
    fileSystem: fs,
    httpClientFactory: httpClientFactoryMemory,
    out: out,
    err: err,
  ).run(arguments);

  Future<bool> exists(String path) => fs.isFile('/out/$host/$path');

  test('scrap', () async {
    expect(
      await run([
        site.uri.toString(),
        '-o',
        '/out',
        '--depth',
        '1',
        '--exclude',
        r'/skip/$',
      ]),
      0,
    );
    expect(await exists('index.html'), isTrue);
    expect(await exists('style.css'), isTrue);
    expect(await exists('page.html'), isTrue);
    expect(await exists('deep.html'), isFalse);
    expect(await exists('skip/index.html'), isFalse);
    final text = out.toString();
    expect(text, contains('  200 ${site.uri} -> $host/index.html'));
    expect(
      text,
      contains('  404 ${site.url('broken.html')} (from ${site.uri})'),
    );
    expect(text, contains('3 downloaded, 0 cached, 1 failed, saved in /out'));
    expect(err.toString(), isEmpty);

    // Second run from cache, quiet
    out.clear();
    expect(
      await run([
        site.uri.toString(),
        '-o',
        '/out',
        '-d',
        '1',
        '--exclude',
        r'/skip/$',
        '-q',
      ]),
      0,
    );
    expect(
      out.toString(),
      '  404 ${site.url('broken.html')} (from ${site.uri})\n'
      '4 urls: 0 downloaded, 3 cached, 1 failed, saved in /out\n',
    );
  });

  test('include', () async {
    expect(
      await run([site.uri.toString(), '-o', '/out', '--include', r'page']),
      0,
    );
    expect(await exists('index.html'), isTrue);
    expect(await exists('page.html'), isTrue);
    expect(await exists('style.css'), isFalse);
  });

  test('start url failure', () async {
    expect(await run([site.url('none.html'), '-o', '/out']), 1);
  });

  test('usage', () async {
    expect(await run(['--help']), 0);
    expect(out.toString(), contains('Usage: web_scrapper [options] <url>'));
    expect(out.toString(), contains('--external-resources'));
    for (final arguments in [
      <String>[],
      ['--depth', 'x', 'example.com'],
      ['--include', '(', 'example.com'],
      ['--header', 'no_colon', 'example.com'],
      ['ftp://example.com'],
      ['--unknown'],
    ]) {
      err.clear();
      expect(
        await run(arguments),
        webScrapperExitCodeUsage,
        reason: '$arguments',
      );
      expect(err.toString(), contains('Usage:'));
    }
  });
}
