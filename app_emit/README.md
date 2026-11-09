# tekartik_app_emit

A completer that can be cancelled and whose value can be read
synchronously once available. The producer holds an
`EmitFutureOrController<T>` (`complete`, `completeError`, `cancel`,
`close`); the consumer gets an `EmitFutureOr<T>`, whose `toFutureOr()` is
the value itself once there and a `Future` before. Handy for lazily loaded
items: a list item already in cache is built at once, without waiting a
frame.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_emit:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_emit
```

```dart
import 'package:tekartik_app_emit/emit.dart';

Future<void> main() async {
  var controller = EmitFutureOrController<String>();
  var futureOr = controller.futureOr;
  print(futureOr.toFutureOr() is Future); // true, pending
  controller.complete('loaded');
  print(futureOr.toFutureOr()); // loaded, the value itself
  futureOr.listen((value) => print('listen: $value')); // runs at once
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser. No platform
setup. See [example/main.dart](example/main.dart).

## What to use

* `EmitFutureOrController<T>()`: pending; `EmitFutureOrController(value: v)`
  or `(nullValue: true)` is completed at once. Complete it with
  `complete(value)` or `completeError(error)`, give it up with
  `cancel(reason: ...)`, call `close()` when its owner goes away.
* `controller.futureOr` (an `EmitFutureOr<T>`): `toFutureOr()` (`T` or
  `Future<T>`), `toFuture()` (always a `Future<T>`), `listen(onValue,
  onError: ...)`.
* `EmitFutureOr.withValue(value)`: an already completed one.
* `EmitCancelException`: the error of a cancelled controller (`reason`).

## Common pitfalls

* The completer is synchronous: listeners and `then` callbacks run inside
  `complete` and `cancel`, before they return.
* `toFutureOr()` can be a `Future`: test `is Future` before using the
  value (an `await` also works, one microtask later).
* `cancel` completes a pending controller with an `EmitCancelException`:
  `onError` gets it, a `listen` without `onError` ignores it (any other
  error without `onError` is uncaught, as for a stream). A cancel nobody
  listens to is not an uncaught error (since 2026-11-09).
* `subscription.cancel()` cancels the controller itself, for every
  listener.
* `complete` or `completeError` twice throws a `StateError`.
* `EmitFutureOrController(value: null)` stays pending: pass
  `nullValue: true`. `EmitFutureOr.withValue(null)` completes with `null`
  (since 2026-11-09, it stayed pending before).

## Agent skills

[skills/tekartik-app-emit-future-or](skills/tekartik-app-emit-future-or/SKILL.md).
