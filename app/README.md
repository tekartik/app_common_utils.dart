# tekartik_app_common_utils

Pure Dart helpers shared by the Tekartik apps: background work that never
overlaps (`LazyRunner`, `SingleFlight`), one call to release what an object
owns (`AutoDispose`), a YAML config read into a cv `Model`, an asset bundle
abstraction with a memory implementation and a tap code detector.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_common_utils:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app
```

Many edits in a row give a single background save:

```dart
import 'package:tekartik_app_common_utils/lazy_runner.dart';

Future<void> main() async {
  var text = '';
  var saver = LazyRunner<void>(
    action: (index) async {
      print('save #$index: $text');
    },
  );
  for (var edit in ['a', 'ab', 'abc']) {
    text = edit;
    saver.trigger(); // returns at once, the triggers are merged
  }
  await saver.waitTriggered(); // prints "save #0: abc"
  await saver.close();
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser (dart2js and
dart2wasm). No platform setup. See [example/main.dart](example/main.dart).

## What to use

| Import | Main API | Use it to |
|---|---|---|
| `lazy_runner.dart` | `LazyRunner<T>`, `LazyRunner.periodic`: `trigger`, `triggerAndWait`, `waitTriggered`, `close` | run a background action on demand (and/or periodically), triggers during a run give one more run |
| `single_flight.dart` | `SingleFlight<T>`: `run`, `wait`, `waitOrRun`, `close` | share one execution between concurrent callers, cache the last result |
| `auto_dispose.dart` | `AutoDisposeMixin` (`audiAdd*`, `audiDisposeAll`), `AutoDisposerableBase` | release subscriptions, controllers and closures in one call |
| `yaml_utils.dart` | `decodeYamlMap`, `decodeYamlMapOrNull` | read a YAML map as a cv `Model` |
| `asset/asset_bundle.dart` | `TkAssetBundle`, `TkAssetBundleMemory` | load assets in code that does not depend on Flutter |
| `sequence_validator/sequence_validator.dart` | `SequenceValidator(sequence: [2, 3, 1])` | detect a hidden tap code |

## Common pitfalls

* `trigger()` does not report the action errors (printed in debug mode
  only): catch them in the action, or use `triggerAndWait()`, which returns
  the result and rethrows the error.
* Once a `LazyRunner` is closed, `triggerAndWait()` fails with
  `StateError('disposed')`, as does a call waiting behind the last run.
  `debugLazyRunner` is a `const`.
* This `LazyRunner` is not the one of `tekartik_common_utils` (no result, no
  `close`): import only one of them in a file.
* `SingleFlight.run()` after `close()` throws at once (not a failed future).
* `decodeYamlMap` returns a read-only view of the YAML map: nested maps are
  `YamlMap`s (read them as `Map`), keys that are not strings throw when
  read. `decodeYamlMapOrNull` returns null for a null text or a document
  that is not a map, invalid YAML still throws a `YamlException`.
* `TkAssetBundleMemory` throws for a key that was not set.
* `AutoDisposeMixin` keys its objects by `==`: registering an equal object
  replaces the first disposer. A dispose callback must not call
  `audiDispose` on the same owner during `audiDisposeAll()`.

## Agent skills

[skills/](skills/): `tekartik-app-common-utils-async-runners` (LazyRunner,
SingleFlight), `tekartik-app-common-utils-auto-dispose`,
`tekartik-app-common-utils-yaml-assets` (YAML, assets, sequence validator).
