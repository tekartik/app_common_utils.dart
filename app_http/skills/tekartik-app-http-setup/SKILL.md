---
name: tekartik-app-http-setup
description: >-
  Use when an app or package needs an http client that works the same on the
  Dart VM, the web and Flutter with tekartik_app_http: httpClientFactoryUniversal
  (and the legacy httpClientFactory alias), httpClientFactoryIo, httpFactoryIo,
  httpServerFactoryIo, httpClientFactoryBrowser, httpClientFactoryMemory,
  httpServerFactoryMemory, httpFactoryMemory, HttpClientFactory.newClient(),
  httpClientSend/httpClientRead/httpClientReadBytes, the httpStatusCodeOk
  constants, and file downloads with fsDownloadFile / httpFsDownloadFile from
  package:tekartik_app_http/app_http.dart and
  package:tekartik_app_http/app_http_fs_download_file.dart.
---

# Universal http client factory (tekartik_app_http)

`tekartik_app_http` is a thin aggregation package: it re-exports `tekartik_http`
plus the io, browser and memory implementations, and picks the right one at
compile time through `httpClientFactoryUniversal`, so the same code runs on the
VM, in a browser and in Flutter without a conditional import of your own.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_http/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_http:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_http
      version: '>=0.1.0'
  ```
* Main import: `package:tekartik_app_http/app_http.dart`. It re-exports
  `package:tekartik_http/http.dart` (so `Client`, `HttpClientFactory`,
  `HttpFactory`, `HttpServerFactory`, `HttpClientResponse`, `HttpServer`,
  `HttpRequest`, `InternetAddress`, `httpServerGetUri`, `parseUri`,
  `localhost`, `portDynamic`, `isHttpStatusCodeSuccessful` and the
  `httpStatusCode*` / `httpContentType*` constants come with it) and adds the
  platform factories. Do not add `tekartik_http` as a direct dependency just
  for those names.
* Getting a client: `httpClientFactoryUniversal.newClient()` returns a plain
  `package:http` `Client`, so use `get`, `post`, `send`, `read`, `readBytes`
  as usual. Always `close()` it when done (or keep one long-lived client).
* `httpClientFactory` is the older name kept for compatibility and is exactly
  `httpClientFactoryUniversal`; prefer the explicit one in new code.
* Platform-specific factories are also exported and are safe to *import*
  everywhere (they resolve to a throwing stub off-platform):
  `httpClientFactoryIo`, `httpFactoryIo`, `httpServerFactoryIo` (VM/Flutter
  mobile+desktop only) and `httpClientFactoryBrowser` (web only). Only touch
  them when you really need io-only behaviour (a server, socket options);
  otherwise use the universal one. On an unsupported platform reading them
  throws `UnimplementedError`, and `httpClientFactoryUniversal` throws
  `UnsupportedError` when neither `dart:io` nor `dart:js_interop` exists.
* Testing: take an `HttpClientFactory` as a constructor/parameter argument
  instead of calling the global, and pass `httpClientFactoryMemory` (with
  `httpServerFactoryMemory` / `httpFactoryMemory` for an in-memory server) in
  tests. `httpFactoryMemory.client` / `.server` give both sides of the same
  in-memory network.
* Status codes: compare with the exported constants (`httpStatusCodeOk`,
  `httpStatusCodeNotFound`, ...) or use `isHttpStatusCodeSuccessful(code)`
  rather than hard-coded numbers.
* Downloads: `package:tekartik_app_http/app_http_fs_download_file.dart` adds
  `fsDownloadFile(Uri url, File file, {bool? force})` as an extension on both
  `Client` (`HttpClientFsExt`) and `HttpClientFactory`
  (`HttpClientFactoryFsExt`), plus the top level
  `httpFsDownloadFile(url, file, {force})` which uses the universal factory.
  `File` here is the `fs_shim` `File` (the library re-exports
  `package:fs_shim/fs_shim.dart`), not `dart:io`'s.
* `fsDownloadFile` is a no-op when the file already exists: pass `force: true`
  to re-download. It streams the body to the file, throws `ClientException` on
  a non successful status and deletes any partial file on error. The factory
  variant creates and closes its own client.
* Anti-patterns: importing `dart:io`'s `HttpClient` or `package:http` directly
  in shared code; using `dart:io` `File` with `fsDownloadFile`; calling
  `httpClientFactoryIo` from code that also runs on the web; forgetting
  `client.close()`.

## Examples

### Universal GET, works on VM, web and Flutter

```dart
import 'package:tekartik_app_http/app_http.dart';

Future<void> main() async {
  var client = httpClientFactoryUniversal.newClient();
  try {
    var response = await client.get(Uri.parse('https://www.github.com'));
    if (isHttpStatusCodeSuccessful(response.statusCode)) {
      print('${response.statusCode} ${response.body.length} bytes');
    } else {
      print('failed: ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}
```

### Inject the factory so the code is testable with the memory implementation

```dart
import 'package:tekartik_app_http/app_http.dart';

class ApiClient {
  final HttpClientFactory httpClientFactory;
  final Uri baseUri;

  ApiClient({HttpClientFactory? httpClientFactory, required this.baseUri})
    : httpClientFactory = httpClientFactory ?? httpClientFactoryUniversal;

  Future<String> fetch(String path) async {
    var client = this.httpClientFactory.newClient();
    try {
      return await httpClientRead(client, httpMethodGet, baseUri.resolve(path));
    } finally {
      client.close();
    }
  }
}

Future<void> main() async {
  // In a test: ApiClient(httpClientFactory: httpClientFactoryMemory, ...)
  var api = ApiClient(baseUri: Uri.parse('https://example.com'));
  print(await api.fetch('index.html'));
}
```

### In-memory client and server (unit tests, no network)

```dart
import 'package:tekartik_app_http/app_http.dart';

Future<void> main() async {
  var server = await httpServerFactoryMemory.bind(
    InternetAddress.anyIPv4,
    portDynamic,
  );
  server.listen((request) {
    request.response
      ..statusCode = httpStatusCodeOk
      ..write('hello')
      ..close();
  });
  var uri = httpServerGetUri(server);

  var client = httpClientFactoryMemory.newClient();
  var response = await client.get(uri);
  print('${response.statusCode}: ${response.body}'); // 200: hello
  client.close();
  await server.close();
}
```

### Download a file to an fs_shim file

```dart
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_http/app_http_fs_download_file.dart';

Future<void> main() async {
  var fs = fileSystemDefault;
  var file = fs.file(fs.path.join('.local', 'v0.js'));
  var url = Uri.parse('https://cdn.ampproject.org/v0.js');

  // Skipped if the file is already there.
  await httpFsDownloadFile(url, file);

  // Same thing, explicitly using a factory (creates/closes its own client).
  await httpClientFactoryUniversal.fsDownloadFile(url, file, force: true);

  // Or reuse one client for several downloads.
  var client = httpClientFactoryUniversal.newClient();
  try {
    await client.fsDownloadFile(url, file, force: true);
  } catch (e) {
    // ClientException on a non successful status code.
    print('download failed: $e');
  } finally {
    client.close();
  }
  print((await file.stat()).size);
}
```
