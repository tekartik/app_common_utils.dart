---
name: tekartik-app-media-mime-types
description: >-
  Use when mapping between file names, file extensions and mime (content) types
  in Dart with tekartik_app_media: filenameMimeType, extensionMimeType,
  extensionFromMimeType and the constants mimeTypeApplicationJson,
  mimeTypeImagePng, mimeTypeImageJpg, mimeTypeImageWebp,
  mimeTypeApplicationZip, mimeTypeOctetStream, extensionApplicationJson,
  extensionImagePng, extensionImageJpg, extensionImageWebp,
  extensionApplicationZip, from package:tekartik_app_media/mime_type.dart.
---

# Mime types and file extensions (tekartik_app_media)

`tekartik_app_media` is a thin, platform independent wrapper over
`package:mime`: three lookup functions that always use a leading `.` for
extensions, plus `const` mime type / extension pairs for the formats used
across the Tekartik apps.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_media/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_media:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_media
  ```
* Single import: `package:tekartik_app_media/mime_type.dart`. It exports the
  three functions and all the constants; nothing else. It is pure Dart (no
  `dart:io`), so it works on the VM, on the web and in Flutter.
* `String filenameMimeType(String filename)` - never returns null: it falls
  back to `mimeTypeOctetStream` (`application/octet-stream`). Use it when
  setting a `content-type` header or a storage upload metadata from a file
  name.
* `String? extensionMimeType(String extension)` - returns null for an unknown
  extension. It accepts `'png'`, `'.png'` or even a whole file name (it keeps
  what follows the last `.`, lower-cased), so it is the nullable variant of
  `filenameMimeType`. Use it when an unknown type must be detected rather than
  defaulted.
* `String? extensionFromMimeType(String mimeType)` - the reverse lookup,
  returning the extension **with** its leading dot (`'.png'`), unlike
  `package:mime`'s `extensionFromMime`. Null when unknown. Handy to name a
  downloaded blob whose type is known.
* Extra mapping on top of `package:mime`: `.yaml` <-> `application/yaml`,
  which `package:mime` does not know. Everything else comes from
  `package:mime`'s table (`.css`, `.dart`, `.gif`, `.html`, `.ico`, `.js`,
  `.svg`, `.txt`, `.woff`, `.woff2`, `.wasm`, `.pdf`, `.mp4`, `.ics`, ...).
* Use the constants instead of string literals when comparing or building
  values: `mimeTypeApplicationJson`, `mimeTypeImagePng`, `mimeTypeImageJpg`
  (`image/jpeg`), `mimeTypeImageWebp`, `mimeTypeApplicationZip`,
  `mimeTypeOctetStream`, and the matching `extensionApplicationJson`,
  `extensionImagePng`, `extensionImageJpg` (`.jpg`), `extensionImageWebp`,
  `extensionApplicationZip`. They are `const`, so they can be used in `const`
  lists, switch cases and default parameter values.
* Round-trip caveat: `image/jpeg` maps back to `.jpg`, so
  `extensionFromMimeType(extensionMimeType('.jpeg')!)` gives `.jpg`, not
  `.jpeg`. Do not assume the reverse lookup returns the original extension.
* Anti-patterns: hard-coding `'image/png'`; forgetting that
  `extensionFromMimeType` includes the dot and producing `file..png`; calling
  `filenameMimeType` when a null result would be meaningful (use
  `extensionMimeType`); adding a direct dependency on `package:mime` for these
  lookups.

## Examples

### Content type of a file name, and naming a file from a content type

```dart
import 'package:tekartik_app_media/mime_type.dart';

void main() {
  print(filenameMimeType('photo.png')); // image/png
  print(filenameMimeType('doc.pdf')); // application/pdf
  print(filenameMimeType('README')); // application/octet-stream

  print(extensionMimeType('webp')); // image/webp
  print(extensionMimeType('.yaml')); // application/yaml
  print(extensionMimeType('.unknown')); // null

  print(extensionFromMimeType(mimeTypeImageJpg)); // .jpg
  print(extensionFromMimeType(mimeTypeApplicationZip)); // .zip
  print(extensionFromMimeType('application/nope')); // null
}
```

### Upload metadata, with a guard on unsupported types

```dart
import 'package:tekartik_app_media/mime_type.dart';

const supportedImageMimeTypes = [
  mimeTypeImagePng,
  mimeTypeImageJpg,
  mimeTypeImageWebp,
];

String? imageContentType(String filename) {
  var mimeType = extensionMimeType(filename);
  if (mimeType == null || !supportedImageMimeTypes.contains(mimeType)) {
    return null;
  }
  return mimeType;
}

void main() {
  print(imageContentType('avatar.webp')); // image/webp
  print(imageContentType('avatar.jpeg')); // image/jpeg
  print(imageContentType('avatar.gif')); // null (not supported here)

  // Always a value for a generic upload.
  print(filenameMimeType('archive.zip')); // application/zip
}
```

### Naming a downloaded blob from its content type

```dart
import 'package:tekartik_app_media/mime_type.dart';

String downloadFilename(String baseName, String? contentType) {
  var extension = contentType == null
      ? null
      : extensionFromMimeType(contentType);
  // extensionFromMimeType already includes the leading dot.
  return '$baseName${extension ?? ''}';
}

void main() {
  print(downloadFilename('export', mimeTypeApplicationJson)); // export.json
  print(downloadFilename('export', mimeTypeOctetStream)); // export.bin
  print(downloadFilename('export', null)); // export
}
```
