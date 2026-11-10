# tekartik_app_http

One http client factory for code that runs on the Dart VM, in the browser and
in Flutter: `httpClientFactoryUniversal` is the `dart:io` client on the VM and
Flutter, the browser client on the web, picked at compile time. It re-exports
[tekartik_http](https://github.com/tekartik/http.dart) (the `HttpClientFactory`
API, the memory client and server for tests) and adds file downloads to an
fs_shim file.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_http:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_http
```

```dart
import 'package:tekartik_app_http/app_http.dart';

Future<void> main() async {
  var client = httpClientFactoryUniversal.newClient();
  try {
    var response = await client.get(Uri.parse('https://example.com/'));
    print('${response.statusCode} ${response.body.length} chars');
  } finally {
    client.close();
  }
}
```

The client is a `package:http` `Client` (`get`, `post`, `read`, `send`...).
See [example/main.dart](example/main.dart).

## Platforms

* Dart VM and Flutter (Android, iOS, desktop): `dart:io` client
  (`httpClientFactoryIo`).
* Browser and Flutter web (dart2js, dart2wasm): the browser client
  (`httpClientFactoryBrowser`); the server must allow the page origin (CORS).
* Tests on any platform: `httpClientFactoryMemory` with
  `httpServerFactoryMemory` (no network).

## What to use

* `package:tekartik_app_http/app_http.dart`: `httpClientFactoryUniversal`, the
  memory factories, the io factories (`httpClientFactoryIo`, `httpFactoryIo`,
  `httpServerFactoryIo`: they throw `UnimplementedError` on the web) and
  `httpClientFactoryBrowser` (throws off the web); `httpClientFactory` is the
  old name of `httpClientFactoryUniversal`.
* `package:tekartik_app_http/app_http_fs_download_file.dart`:
  `fsDownloadFile(url, file, {force})` on a `Client` or an
  `HttpClientFactory`, and `httpFsDownloadFile(url, file, {force})` (universal
  factory). The file is an fs_shim `File`.

## Common pitfalls

* Close the clients you create (`client.close()`).
* Take an `HttpClientFactory` parameter in your code instead of the global:
  tests pass `httpClientFactoryMemory`.
* `fsDownloadFile` does nothing when the file exists: pass `force: true` to
  download it again. A failed status throws a `ClientException` and leaves
  the file untouched; a transfer failing in the middle deletes the file,
  the previous copy included when `force` is true.

## Agent skills

[skills/tekartik-app-http-setup](skills/tekartik-app-http-setup/SKILL.md).
