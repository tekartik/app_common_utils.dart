# tekartik_app_web_scrapper

Static web site scrapper: downloads start urls, follows their links and saves
every file to a [fs_shim](https://pub.dev/packages/fs_shim) directory as
`<host>/<path>`. Html is parsed with
[tekartik_html](https://github.com/tekartik/html.dart), requests go through
`tekartik_app_http`.

Links followed:

- html: anchors (pages), stylesheets, icons, preloads, scripts (external and
  inline), import maps, images (`srcset`, lazy `data-src`), video/audio,
  iframes, `<object>`, meta refresh, `og:image`, `<style>` and `style=""`.
- css: `url(...)` and `@import`.
- javascript: static/dynamic imports, `export ... from`, `new URL(x,
  import.meta.url)`, bare specifiers through the page import map.
- optionally (`scanStrings`), javascript and json string literals that look
  like file paths (`'media.json'`, `"img/logo.png"`), for single page apps
  loading data with `fetch`.

Javascript is not executed: content built at runtime from computed urls is
not found (add start urls or links from `onContent`). Links are not rewritten.

## Setup

```yaml
dependencies:
  tekartik_app_web_scrapper:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_web_scrapper
    version: '>=0.1.0'
```

## Command line

```bash
dart run tekartik_app_web_scrapper:web_scrapper https://example.com/ -o .local/site
```

The same binary anywhere else (any package depending on
`tekartik_app_web_scrapper`), i.e. `bin/web_scrapper.dart`:

```dart
import 'package:tekartik_app_web_scrapper/app_web_scrapper_cli.dart';

Future<void> main(List<String> arguments) => webScrapperMain(arguments);
```

Options (`--help`):

| Option | |
|---|---|
| `-o, --out <dir>` | output directory (default `.`), files saved as `<dir>/<host>/<path>` |
| `-d, --depth <n>` | maximum page depth, `0` for the start pages only (their resources are always downloaded) |
| `--external-resources` | also download images/styles/scripts/fonts/media hosted on other domains |
| `--external-links` | also download pages linked on other domains (one hop, their own links are not followed) |
| `--scan-strings` | also follow javascript/json strings looking like file paths |
| `--host <host>` | extra host part of the site (i.e. `www.example.com`) |
| `--include <regexp>` / `--exclude <regexp>` | url filters (multiple, start urls excepted) |
| `--max-files <n>` | stop after n urls |
| `-j, --concurrency <n>` | concurrent requests (default 4) |
| `--delay <ms>` | delay before each request |
| `--header "name: value"` | extra request header (multiple) |
| `-f, --force` | download again files already present |
| `-q, --quiet` | only print failures and the summary |

Exit code: 0 (even with some failed links), 1 if every start url failed, 64
for invalid arguments.

Example, all midi files linked from a page:

```bash
web_scrapper https://example.com/midi/ --depth 1 --include '\.mid$'
```

## Dart API

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';

Future<void> main() async {
  final result = await WebScrapper(
    startUris: [Uri.parse('https://example.com/')],
    outDirectory: fileSystemDefault.directory('.local/site'),
    options: WebScrapperOptions(
      maxDepth: 2,
      filter: (uri) => !uri.path.startsWith('/private/'),
      onContent: (content) {
        // content.text, content.document (html), content.headers,
        // content.readBytes(); add or remove content.links.
      },
    ),
  ).run();
  print(result); // n urls: x downloaded, y cached, z failed
}
```

`WebScrapperCli` embeds the command line with an injected file system, http
client factory, content handler and output (see `test/cli_test.dart`).

## Rules

- Depth: start urls are at depth 0, page links increase the depth, resources
  keep the depth of the content referencing them.
- Domains: the hosts of the start urls (plus `hosts`) form the site, whatever
  the scheme. Other domains are only followed with `followExternalResources`
  / `followExternalLinks`.
- Layout: `<host>[_<port>]/<path>`, `/` gives `index.html`, html without an
  `.html`/`.htm` extension gets `.html` appended (`/about` gives
  `about.html`), a query is inserted before the extension (`app.js?v=2` gives
  `app_v=2.js`). Override with `localPath`, return null to not save.
- Cache: a file already present is not downloaded again but read back to
  follow its links, so an interrupted scrap resumes quickly; `force` to
  download again.
- Failures (http status, network, `onContent` exceptions) are reported as
  failed entries, never thrown.
- `stop()` stops a run: no new request, `run()` completes once the requests
  in progress are done with `WebScrapperResult.stopped` set.
