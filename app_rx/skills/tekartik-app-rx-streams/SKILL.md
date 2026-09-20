---
name: tekartik-app-rx-streams
description: >-
  Use when turning a single-subscription Stream into a shared, replayable one
  with tekartik_app_rx: toBroadcastValueStream() / BroadcastValueStream (value,
  valueOrNull, hasValue, close), toBroadcastStream() / BroadcastStream, the
  deprecated toBehaviorSubject(), TekartikRxStreamExt, the rxdart re-export
  (BehaviorSubject, PublishSubject, ValueStream) of
  package:tekartik_app_rx/rx.dart, and the AutoDisposeRxExtension helpers
  audiAddBehaviorSubject / audiAddBroadcastValueStream from
  package:tekartik_app_rx/auto_dispose.dart.
---

# Broadcast value streams (tekartik_app_rx)

`tekartik_app_rx` is a thin layer over `rxdart`: it re-exports it and adds
lazy broadcast wrappers that only subscribe to the source stream when the
first listener arrives, keep the last value for late listeners, and are closed
explicitly (or by an `AutoDispose` holder).

## Guidelines

* Not on pub.dev, depend on it through git:
  ```yaml
  dependencies:
    tekartik_app_rx:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_rx
      version: '>=0.1.0'
  ```
* Three entry points, each re-exporting `package:rxdart/rxdart.dart` so a
  single import is enough:
  * `package:tekartik_app_rx/rx.dart` - only the rxdart re-export
    (`BehaviorSubject`, `PublishSubject`, `ReplaySubject`, `ValueStream`, the
    rx operators...).
  * `package:tekartik_app_rx/helpers.dart` - `TekartikRxStreamExt` plus the
    `BroadcastValueStream` and `BroadcastStream` types.
  * `package:tekartik_app_rx/auto_dispose.dart` - `AutoDisposeRxExtension` plus
    the whole `tekartik_app_common_utils` auto dispose API.
* `stream.toBroadcastValueStream()` is the one to reach for: it returns a
  `BroadcastValueStream<T>` (a `ValueStream`) backed by a sync
  `BehaviorSubject`. It does not listen to the source until the first
  `listen()`/`first`, every listener gets the current value immediately, and
  `value`, `valueOrNull`, `hasValue`, `hasError`, `error`, `errorOrNull`,
  `stackTrace` and `lastEventOrNull` are available.
* `stream.toBroadcastStream()` is the same without value replay (a
  `PublishSubject`): use it for events, where a late listener must not see the
  previous one. Beware of the name: this is the extension from this package,
  it shadows nothing but is not `Stream.asBroadcastStream()`.
* `toBehaviorSubject()` is `@Deprecated('Use toBroadcastValueStream')`. It
  differs in one way: it cancels the source subscription when the last
  listener leaves and never re-subscribes. Migrate to
  `toBroadcastValueStream()`.
* Both wrappers subscribe once and keep the subscription until `close()`, even
  when all listeners cancel. Always `await stream.close()` (it cancels the
  source subscription and closes the subject) - a leak otherwise, especially
  with an infinite source.
* Reading `value` before the first event throws (`ValueStreamError`): guard
  with `hasValue` or use `valueOrNull`. Nothing is emitted until something
  listens, so `hasValue` is false on a freshly created wrapper.
* With a class that mixes in `AutoDisposeMixin` (see
  `tekartik-app-common-utils-auto-dispose`),
  register the rx objects so `audiDisposeAll()` closes them:
  `audiAddBehaviorSubject(subject)`, `audiAddBroadcastValueStream(stream)`,
  and the generic `audiAddStreamController(subject)` /
  `audiAddStreamSubscription(subscription)`.
* Pure Dart, no io/web specific code: works on the VM, the browser and
  Flutter. Tests live in `test/helpers_test.dart`, run with `dart test`.
* Anti-patterns: calling `toBroadcastValueStream()` on each rebuild/each
  access (create it once and share it); forgetting `close()`; using
  `BehaviorSubject` directly when the source is already a stream; expecting
  the source stream to be listened to before the first subscriber.

## Examples

### Share a stream and keep its last value

```dart
import 'dart:async';

import 'package:tekartik_app_rx/helpers.dart';

Future<void> main() async {
  var controller = StreamController<int>(sync: true);

  // Nothing is listened to yet.
  var shared = controller.stream.toBroadcastValueStream();
  print(shared.hasValue); // false

  var sub1 = shared.listen((value) => print('sub1: $value'));
  controller.add(1);
  print(shared.value); // 1

  // A late listener gets the current value right away.
  var sub2 = shared.listen((value) => print('sub2: $value'));
  controller.add(2);

  print(shared.valueOrNull); // 2
  await sub1.cancel();
  await sub2.cancel();

  // Mandatory: closes the subject and cancels the source subscription.
  await shared.close();
  await controller.close();
}
```

### Events without replay

```dart
import 'dart:async';

import 'package:tekartik_app_rx/helpers.dart';

/// A tiny event bus: late listeners must not see past events.
class EventBus {
  final _controller = StreamController<String>(sync: true);
  late final BroadcastStream<String> events = _controller.stream
      .toBroadcastStream();

  void add(String event) => _controller.add(event);

  Future<void> close() async {
    await events.close();
    await _controller.close();
  }
}

Future<void> main() async {
  var bus = EventBus();
  var subscription = bus.events.listen((event) => print('event: $event'));
  bus.add('started');
  await subscription.cancel();
  await bus.close();
}
```

### A controller-like object with auto dispose

```dart
import 'dart:async';

import 'package:tekartik_app_rx/auto_dispose.dart';
import 'package:tekartik_app_rx/helpers.dart';

/// Everything registered is closed by a single audiDisposeAll().
class CounterController with AutoDisposeMixin {
  final _subject = BehaviorSubject<int>.seeded(0);

  late final ValueStream<int> count = _subject.stream;
  late final BroadcastValueStream<int> doubled;

  CounterController() {
    audiAddBehaviorSubject(_subject);
    doubled = audiAddBroadcastValueStream(
      _subject.map((value) => value * 2).toBroadcastValueStream(),
    );
    audiAddStreamSubscription(
      doubled.listen((value) => print('doubled: $value')),
    );
  }

  void increment() => _subject.add(_subject.value + 1);

  void dispose() => audiDisposeAll();
}

Future<void> main() async {
  var controller = CounterController();
  controller.increment();
  print(controller.count.value); // 1
  await Future<void>.delayed(Duration.zero);
  controller.dispose();
}
```

### Only rxdart

```dart
// Single import, no need to depend on rxdart directly.
import 'package:tekartik_app_rx/rx.dart';

Future<void> main() async {
  var subject = BehaviorSubject<String>.seeded('init');
  subject.add('hello');
  print(subject.value); // hello
  print(await subject.first); // hello
  await subject.close();
}
```
