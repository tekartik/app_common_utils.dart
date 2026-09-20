---
name: tekartik-app-common-utils-yaml-assets
description: >-
  Use when depending on tekartik_app_common_utils and needing its YAML-to-cv
  helpers (decodeYamlMap, decodeYamlMapOrNull returning a cv Model), the
  abstracted asset bundle (TkAssetBundle, TkAssetBundleMemory, loadString,
  loadBytes, loadByteData, setString, setBytes), the tap SequenceValidator, or
  the common_utils_import.dart barrel import.
---

# YAML, assets and setup (tekartik_app_common_utils)

`tekartik_app_common_utils` is the dependency-light base of the Tekartik app
packages: it only needs `tekartik_common_utils`, `cv`, `yaml` and
`synchronized`, so it is safe to use from pure Dart, Flutter and web code.
This skill covers the small standalone helpers; see the sibling skills for
`auto_dispose.dart` and for `LazyRunner`/`SingleFlight`.

## Guidelines

* Dependency (git, not on pub.dev - the package is inside the `app/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_common_utils:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app
  ```
* Barrel import: `package:tekartik_app_common_utils/common_utils_import.dart`
  re-exports `package:tekartik_common_utils/common_utils_import.dart` (which
  brings `dart:async`, `package:meta`, `package:synchronized` and the common
  utils extensions) plus this package's `yaml_utils.dart`. Use it in the
  package's own code style; prefer the precise imports below in app code.

### YAML

* `package:tekartik_app_common_utils/yaml_utils.dart` exposes two functions
  built on `package:yaml` + `package:cv`:
  * `Model decodeYamlMap(String yaml)` - parses and converts to a `cv`
    `Model` (a `Map<String, Object?>`); throws `ArgumentError` when the
    document is not a map (for instance a YAML list), and lets `yaml`
    parse errors through.
  * `Model? decodeYamlMapOrNull(String? yaml)` - returns `null` for a null
    input or a non-map document, so it is the right call for optional config
    files.
* The result is a plain deep-converted model: nested maps become `Model`s,
  read them with the `cv` accessors (`model['key']`,
  `model.getValue<String>('key')`) or build a `CvModel` from it. Unlike
  `loadYaml`, the result is mutable and JSON-encodable.

### Assets

* `package:tekartik_app_common_utils/asset/asset_bundle.dart` defines
  `TkAssetBundle`, an abstraction over Flutter's `rootBundle` with
  `Future<String> loadString(String key)`, `Future<Uint8List> loadBytes(String
  key)` and `Future<ByteData> loadByteData(String key)`. Take a
  `TkAssetBundle` in shared code so it stays free of `package:flutter`.
* `TkAssetBundleMemory` is the in-memory implementation used for tests and
  for generated content: fill it with `setString(key, value)` /
  `setBytes(key, bytes)`. Loading a key that was never set throws (the
  internal map lookup is `!`-asserted), so seed every key a test reads.
* A Flutter implementation is not provided here: wrap `rootBundle` in your app
  with a class implementing `TkAssetBundle`.

### Sequence validator

* `package:tekartik_app_common_utils/sequence_validator/sequence_validator.dart`
  provides `SequenceValidator(sequence: [2, 3, 1])`: a morse-like tap/click
  code detector (groups of quick taps separated by pauses), typically wired to
  a hidden gesture that unlocks a debug screen.
* `validate([int? timestamp])` returns a `FutureOr<bool>`: `false` while the
  code is incomplete, and a `Future<bool>` on the last expected tap that
  completes with `true` after a 500ms grace period (or `false` if another tap
  arrives). Always `await` the result before acting on it. Taps inside a group
  must be at most 500ms apart, groups at least 500ms apart, and more than
  1500ms of silence restarts the sequence. Pass `timestamp` (milliseconds)
  only in tests; `restart()` resets the state.

## Examples

### Read an optional YAML config into a cv Model

```dart
import 'package:cv/cv.dart';
import 'package:tekartik_app_common_utils/yaml_utils.dart';

void main() {
  var text = '''
name: my_app
version: 1.2.3
flags:
  debug: true
''';
  Model model = decodeYamlMap(text);
  print(model['name']); // my_app
  print(model.getValue<String>('version')); // 1.2.3
  print((model['flags'] as Model)['debug']); // true

  // Optional file content: null in, null out, no throw on a non map document.
  Model? optional = decodeYamlMapOrNull(null);
  print(optional); // null
  print(decodeYamlMapOrNull('- a list')); // null
}
```

### Shared code taking a TkAssetBundle, tested in memory

```dart
import 'package:tekartik_app_common_utils/asset/asset_bundle.dart';
import 'package:tekartik_app_common_utils/yaml_utils.dart';

Future<String> readAppName(TkAssetBundle bundle) async {
  var model = decodeYamlMap(await bundle.loadString('assets/config.yaml'));
  return model['name'] as String;
}

Future<void> main() async {
  var bundle = TkAssetBundleMemory()
    ..setString('assets/config.yaml', 'name: my_app');
  print(await readAppName(bundle)); // my_app
}
```

### Binary assets in memory

```dart
import 'dart:typed_data';

import 'package:tekartik_app_common_utils/asset/asset_bundle.dart';

Future<void> main() async {
  var bundle = TkAssetBundleMemory()
    ..setBytes('assets/data.bin', Uint8List.fromList([1, 2, 3]));
  var bytes = await bundle.loadBytes('assets/data.bin');
  var byteData = await bundle.loadByteData('assets/data.bin');
  print('${bytes.length} bytes, first: ${byteData.getUint8(0)}');
}
```

### Hidden tap code

```dart
import 'package:tekartik_app_common_utils/sequence_validator/sequence_validator.dart';

class DebugUnlocker {
  /// 2 quick taps, pause, 3 quick taps, pause, 1 tap.
  final validator = SequenceValidator(sequence: <int>[2, 3, 1]);

  Future<void> onTap() async {
    if (await validator.validate() == true) {
      print('unlocked');
      validator.restart();
    }
  }
}
```
