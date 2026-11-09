---
name: tekartik-app-archive-gzip
description: >-
  Use when gzipping or ungzipping text and bytes in code that must also run on
  the web (no dart:io GZipCodec) with tekartik_app_archive: gzipText,
  ungzipText, gzipBytes, ungzipBytes, the noDate and operatingSystem options,
  gzipOperatingSystemUnknown, gzipOperatingSystemLinux and the
  package:tekartik_app_archive/gzip.dart import.
---

# Gzip text and bytes (tekartik_app_archive)

`tekartik_app_archive` wraps `package:archive`'s `GZipEncoder`/`GZipDecoder`
in four `Uint8List`-based functions that behave identically on the Dart VM,
on the web and in Flutter - unlike `dart:io`'s `gzip` codec, which does not
exist in a browser.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_archive/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_archive:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_archive
  ```
* Single import: `package:tekartik_app_archive/gzip.dart`. It exports
  `gzipText`, `ungzipText`, `gzipBytes`, `ungzipBytes`,
  `gzipOperatingSystemUnknown` and `gzipOperatingSystemLinux` - nothing else.
* Text helpers: `Uint8List gzipText(String text, {bool? noDate, int?
  operatingSystem})` encodes as UTF-8 then gzips; `String ungzipText(Uint8List
  data)` gunzips then decodes UTF-8. Use them for JSON payloads, logs and any
  string blob; they round-trip non-ASCII correctly.
* Byte helpers: `Uint8List gzipBytes(Uint8List bytes, {bool? noDate, int?
  operatingSystem})` and `Uint8List ungzipBytes(Uint8List data)`. Both take
  and return `Uint8List`, not `List<int>`: convert with
  `Uint8List.fromList(...)` or `asUint8List(...)` from
  `package:tekartik_common_utils/byte_utils.dart` before calling.
* `noDate: true` zeroes the 4 mtime bytes (header offsets 4..7) of the gzip
  header. Pass it whenever the output is hashed, compared, cached by content
  or stored in a git-tracked file: on the web the encoder writes the current
  time (in seconds) there, so the same input gives other bytes a second
  later (the VM and Flutter, through `dart:io` zlib, already write 0).
* `operatingSystem:` overwrites header byte 9. Use the provided constants
  `gzipOperatingSystemLinux` (3) or `gzipOperatingSystemUnknown` (255) to pin
  it, again for reproducible output (`dart:io` zlib writes its own OS code,
  3 on Linux; the web encoder writes 255).
* Reproducible means identical bytes from one call to the next on one
  platform. The compressed body comes from `dart:io` zlib on the VM and in
  Flutter and from `package:archive`'s Dart port on the web: identical
  output between them is not guaranteed.
* There is no streaming API and no file API: everything is in memory, so keep
  payload sizes reasonable (a few MB) especially on the web.
* Decoding invalid, cut or modified data throws an `ArchiveException` (a
  `FormatException`; `ArchiveChecksumException` for a wrong CRC), and
  `ungzipText` throws a `FormatException` for bytes that are not UTF-8:
  catch `FormatException` around `ungzipBytes`/`ungzipText` when the input
  comes from the network or from user files. Since 2026-11-09 the decoding
  checks the CRC (`verify: true`): with `package:archive` 4.6.0, whose
  decoders no longer throw by default, a damaged input gave empty, partial
  or wrong bytes without error.
* Anti-patterns: expecting `gzipBytes` output to be stable without
  `noDate: true`; passing a `List<int>` where a `Uint8List` is required;
  reaching for `dart:io`'s `GZipCodec` in code shared with web targets.

## Examples

### Round-trip a JSON payload

```dart
import 'dart:convert';

import 'package:tekartik_app_archive/gzip.dart';

void main() {
  var data = {'name': 'étoile', 'values': List.generate(100, (i) => i)};
  var compressed = gzipText(jsonEncode(data));
  print('${compressed.length} bytes');
  var decoded = jsonDecode(ungzipText(compressed)) as Map<String, Object?>;
  print(decoded['name']); // étoile
}
```

### Reproducible output (content hashing, golden files)

```dart
import 'package:tekartik_app_archive/gzip.dart';

void main() {
  var text = 'hello world';
  var first = gzipText(
    text,
    noDate: true,
    operatingSystem: gzipOperatingSystemLinux,
  );
  var second = gzipText(
    text,
    noDate: true,
    operatingSystem: gzipOperatingSystemLinux,
  );
  // Identical bytes: safe to hash or store as a golden file.
  print(first.toString() == second.toString());
}
```

### Compress binary data with a safe decode

```dart
import 'dart:typed_data';

import 'package:tekartik_app_archive/gzip.dart';

Uint8List? tryUngzip(Uint8List data) {
  try {
    return ungzipBytes(data);
  } catch (e) {
    print('not gzip data: $e');
    return null;
  }
}

void main() {
  var bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
  var compressed = gzipBytes(bytes, noDate: true);
  print('${bytes.length} -> ${compressed.length}');
  print(tryUngzip(compressed)?.length); // 1024
  print(tryUngzip(Uint8List.fromList([1, 2, 3]))); // null
}
```
