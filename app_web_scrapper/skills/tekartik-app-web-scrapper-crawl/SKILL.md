---
name: tekartik-app-web-scrapper-crawl
description: >-
  Use when downloading, mirroring or parsing a static web site with
  tekartik_app_web_scrapper: WebScrapper (startUris, outDirectory fs_shim
  Directory, run, WebScrapperResult downloaded/cached/failed),
  WebScrapperOptions (maxDepth, followExternalResources, followExternalLinks,
  scanStrings, hosts, filter, maxFiles, concurrency, delay, force, headers,
  localPath, onContent, onEntry), WebScrapperContent (text, document,
  headers, readBytes, links), WebScrapperEntry, WebScrapperLinkExtractor,
  webScrapperDefaultLocalPath, WebScrapper.stop, and the web_scrapper command line
  (webScrapperMain, WebScrapperCli) from app_web_scrapper_cli.dart.
---

# Static web site scrapper (tekartik_app_web_scrapper)

`WebScrapper` downloads start urls and follows their links (html, css,
javascript imports, optionally javascript/json strings), saving each file to a
fs_shim `Directory` as `<host>/<path>`. Pure Dart (fs_shim + tekartik_app_http
+ tekartik_html), the command line part is io only.

## Guidelines

* Dependency (git, `app_web_scrapper/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_web_scrapper:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_web_scrapper
      version: '>=0.1.0'
  ```
* Imports: `package:tekartik_app_web_scrapper/app_web_scrapper.dart` (api) and
  `package:tekartik_app_web_scrapper/app_web_scrapper_cli.dart` (command line,
  re-exports the api, uses `dart:io`).
* A binary is two lines: import `app_web_scrapper_cli.dart` and
  `Future<void> main(List<String> arguments) => webScrapperMain(arguments);`.
  Prepend fixed arguments to make a site specific tool
  (`webScrapperMain(['https://site/', '--out', '.local/site', ...arguments])`).
* `WebScrapper(startUris:, outDirectory:, options:, httpClientFactory:,
  htmlProvider:)`: start urls must be absolute http(s) (`ArgumentError`
  otherwise); `outDirectory` null saves nothing (use `onContent`);
  `httpClientFactory` defaults to `httpClientFactoryUniversal`, `htmlProvider`
  to `htmlProviderHtml5Lib`. `run()` returns a `WebScrapperResult`; every
  failure (http status, network, file, `onContent` exception) is a failed
  `WebScrapperEntry` (`statusCode`, `error`, `referrer`), only an `onEntry`
  exception aborts the run. `scrapper.stop()` (i.e. from `onEntry`, a timer
  or a key press) stops the run: no new request, `run()` completes once the
  requests in progress are done, with `result.stopped` true.
* Depth: start urls are depth 0; page links (`<a>`, `<area>`, meta refresh)
  add 1 and stop past `maxDepth`; resources (images, css, scripts, fonts,
  iframes, js imports) keep the depth of their referrer, so `maxDepth: 0`
  saves the start pages complete.
* Domains: the start url hosts (host and explicit port, scheme ignored) plus
  `hosts` are the site. `followExternalResources` downloads resources of
  other domains; `followExternalLinks` downloads pages of other domains
  linked from site pages, one hop only.
* `filter(uri)` runs on every found url (not the start urls); the command line
  builds it from `--include`/`--exclude` regular expressions matched on the
  full url.
* `scanStrings`: javascript and json string literals ending with a known file
  extension are followed, resolved against the html page that led to them
  (like `fetch`); needed for apps loading `media.json`-like manifests, at the
  cost of some 404 on false positives.
* Layout (`webScrapperDefaultLocalPath`): `<host>[_<port>]/<path>`, `/` gives
  `index.html`, html without `.html`/`.htm` gets `.html` appended
  (`webScrapperHtmlLocalPath`), queries go before the extension
  (`app.js?v=2` gives `app_v=2.js`). `localPath: (uri) => ...` overrides it
  (relative posix path, null to not save).
* Cache: an existing file is read back instead of downloaded (entry status
  `cached`, `content.fromCache`), its links are still followed; `force: true`
  downloads again. Non text contents are streamed to disk.
* `onContent(content)` runs before links are followed: `content.text`
  (html/css/js/json), `content.document` (html), `content.headers`
  (lowercase, i.e. `content-disposition`), `await content.readBytes()`,
  `content.depth`, `content.referrer`. Add or remove `content.links`
  (`WebScrapperLink(uri)` resource, `WebScrapperLink.page(uri)` page) to steer
  the crawl with a custom parser.
* Tests: serve a fake site with `httpServerFactoryMemory` and pass
  `httpClientFactory: httpClientFactoryMemory` and a
  `newFileSystemMemory()` directory; `WebScrapperCli(fileSystem:,
  httpClientFactory:, out:, err:)` runs the command line the same way.

## Examples

### Clone a site from a tool

```dart
import 'package:tekartik_app_web_scrapper/app_web_scrapper_cli.dart';

/// dart run tool/scrap_site.dart [--force]
Future<void> main(List<String> arguments) => webScrapperMain([
  'https://example.com/',
  '--out',
  '.local/site',
  '--scan-strings',
  ...arguments,
]);
```

### Parse pages while crawling

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';

Future<void> main() async {
  final titles = <Uri, String>{};
  final result = await WebScrapper(
    startUris: [Uri.parse('https://example.com/list/A')],
    outDirectory: fileSystemDefault.directory('.local/site'),
    options: WebScrapperOptions(
      maxDepth: 2,
      concurrency: 2,
      delay: const Duration(milliseconds: 200),
      filter: (uri) =>
          uri.path.startsWith('/list/') || uri.path.startsWith('/download/'),
      onContent: (content) async {
        final document = content.document;
        if (document != null) {
          titles[content.uri] = document.title;
          // Follow a url the default extractor cannot see.
          final next = document.body.querySelector('[data-next]');
          final href = next?.getAttribute('data-next');
          if (href != null) {
            content.links.add(WebScrapperLink.page(content.uri.resolve(href)));
          }
        } else if (content.uri.path.startsWith('/download/')) {
          final disposition = content.headers['content-disposition'];
          final bytes = await content.readBytes();
          print('${content.uri} $disposition ${bytes.length} bytes');
        }
      },
    ),
  ).run();
  for (final entry in result.failed) {
    print('${entry.uri} from ${entry.referrer}: ${entry.error}');
  }
  print('$result, ${titles.length} pages');
}
```

### Only parse, save nothing

```dart
import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';

Future<List<String>> midiUrls(Uri page) async {
  final urls = <String>[];
  await WebScrapper(
    startUris: [page],
    options: WebScrapperOptions(
      maxDepth: 0,
      onContent: (content) {
        urls.addAll(
          content.links
              .where((link) => link.uri.path.endsWith('.mid'))
              .map((link) => link.uri.toString()),
        );
        content.links.clear(); // don't download anything else
      },
    ),
  ).run();
  return urls;
}
```

### Test with an in memory site and file system

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';
import 'package:test/test.dart';

void main() {
  test('scrap', () async {
    final server = await httpServerFactoryMemory.bind(
      InternetAddress.anyIPv4,
      portDynamic,
    );
    server.listen((request) async {
      request.response.headers.set('content-type', 'text/html');
      request.response.write('<a href="page.html">page</a>');
      await request.response.close();
    });
    final fs = newFileSystemMemory();
    final result = await WebScrapper(
      startUris: [httpServerGetUri(server)],
      outDirectory: fs.directory('/out'),
      httpClientFactory: httpClientFactoryMemory,
    ).run();
    expect(result.downloaded.length, 2);
    await server.close();
  });
}
```

## Common mistakes

* Expecting javascript to run: urls built at runtime are not found, use
  `scanStrings`, extra start urls or `content.links.add` in `onContent`.
* Expecting links to be rewritten: absolute links to the original site still
  point to it; relative links work when the `<host>` directory is served.
* Forgetting that resources ignore `maxDepth` (use `filter` to skip them).
* Filtering on `uri.toString()` with a scheme: the same host is scrapped for
  http and https links, match on `uri.path` instead.
* Deleting output files to "retry" a failure: failed urls are never saved and
  are requested again on the next run anyway.
