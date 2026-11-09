# tekartik_app_rx

A thin layer over [rxdart](https://pub.dev/packages/rxdart): it re-exports
it and turns a single subscription `Stream` into a shared one that listens
to the source only when the first listener comes, keeps the last value for
late listeners (`toBroadcastValueStream()`) and is closed explicitly. Plus
helpers to close rx objects with `AutoDispose`.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_rx:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_rx
```

```dart
import 'dart:async';

import 'package:tekartik_app_rx/helpers.dart';

Future<void> main() async {
  var controller = StreamController<int>();
  // The source is not listened to yet.
  var shared = controller.stream.toBroadcastValueStream();
  controller.add(1);
  print(await shared.first); // 1
  // A late listener gets the last value at once.
  print(await shared.first); // 1
  print(shared.value); // 1
  // Cancels the source subscription and closes the subject.
  await shared.close();
  await controller.close();
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser. See
[example/main.dart](example/main.dart).

## What to use

* `package:tekartik_app_rx/rx.dart`: rxdart only (`BehaviorSubject`,
  `PublishSubject`, `ValueStream`, the operators).
* `package:tekartik_app_rx/helpers.dart`: rxdart plus
  * `stream.toBroadcastValueStream()`: a `BroadcastValueStream<T>` (a
    `ValueStream`, backed by a sync `BehaviorSubject`): `value`,
    `valueOrNull`, `hasValue`, `error`, `lastEventOrNull`, `close()`.
  * `stream.toBroadcastStream()`: a `BroadcastStream<T>`, the same without
    replay (a `PublishSubject`), for events.
* `package:tekartik_app_rx/auto_dispose.dart`: rxdart, the `AutoDispose`
  API of `tekartik_app_common_utils` and `audiAddBehaviorSubject` /
  `audiAddBroadcastValueStream`.

## Common pitfalls

* The source is listened to once, on the first listener, and until
  `close()`, even when every listener cancelled: always `close()` (or
  register it with `audiAddBroadcastValueStream`).
* A single subscription source can be shared by one wrapper only: create it
  once, not at each build or access.
* `value` before the first event throws: use `hasValue` or `valueOrNull`.
* `lastEventOrNull` is the last event, a value or an error with its stack
  trace, as `BehaviorSubject` (since 2026-11-09: an error after a value gave
  the value).
* `toBehaviorSubject()` is deprecated: it cancels the source when the last
  listener leaves and listens to it again on the next one, which throws for
  a single subscription source.

## Agent skills

[skills/tekartik-app-rx-streams](skills/tekartik-app-rx-streams/SKILL.md).
