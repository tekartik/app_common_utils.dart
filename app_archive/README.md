# tekartik_app_archive

Gzip and gunzip text and bytes in memory, with the same code on the Dart
VM, in Flutter and on the web (where `dart:io`'s `gzip` does not exist). A
thin layer on [archive](https://pub.dev/packages/archive).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_archive:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_archive
```

```dart
import 'package:tekartik_app_archive/gzip.dart';

void main() {
  var compressed = gzipText('{"name": "étoile"}'); // a Uint8List
  print(ungzipText(compressed)); // {"name": "étoile"}
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser (`dart:io`
zlib is used where available). See [example/main.dart](example/main.dart).

## What to use

All from `package:tekartik_app_archive/gzip.dart`:

* `gzipText(text)` / `ungzipText(bytes)`: UTF-8 text.
* `gzipBytes(bytes)` / `ungzipBytes(bytes)`: `Uint8List` in and out.
* `noDate: true` and `operatingSystem: gzipOperatingSystemUnknown` (or
  `gzipOperatingSystemLinux`): the same bytes at every call, to hash or to
  commit the output.

## Common pitfalls

* Damaged, cut or non gzip data throws a `FormatException` (an
  `ArchiveException`): catch it for data from the network or from a file.
  Before 2026-11-09, with archive 4.6.0, such data gave empty, partial or
  wrong bytes without an error.
* Without `noDate: true` the web output holds the current time (it changes
  every second).
* The VM and the web use different compressors: do not expect the same
  bytes from both.
* Everything is in memory, no streaming: keep payloads to a few MB.

## Agent skills

[skills/tekartik-app-archive-gzip](skills/tekartik-app-archive-gzip/SKILL.md).
