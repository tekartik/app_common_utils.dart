---
name: tekartik-app-emit-future-or
description: >-
  Use when Dart code needs a cancellable completer whose value can be read
  synchronously once available and asynchronously before (a cache entry, a
  lazily loaded resource, a request that can be abandoned) with
  tekartik_app_emit: EmitFutureOrController (complete, completeError, cancel,
  close, isCompleted, isCancelled, futureOr), EmitFutureOr (listen, toFutureOr,
  toFuture, EmitFutureOr.withValue), EmitFutureOrSubscription (cancel,
  asFutureOr) and EmitCancelException from package:tekartik_app_emit/emit.dart.
---

# Cancellable FutureOr controller (tekartik_app_emit)

`tekartik_app_emit` wraps a synchronous `Completer<T>` into an
`EmitFutureOrController<T>` that can be cancelled, and exposes it as an
`EmitFutureOr<T>` whose value is returned directly (no `Future`) once it is
available. Small pure Dart package: VM, web and Flutter.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_emit:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_emit
  ```
* Import `package:tekartik_app_emit/emit.dart`; it exports
  `EmitFutureOrController`, `EmitFutureOr`, `EmitFutureOrSubscription` and
  `EmitCancelException`, nothing else.
* Producer side: create `EmitFutureOrController<T>()`, hand out
  `controller.futureOr` (a new `EmitFutureOr<T>` view on the same
  controller each time), then call exactly one of `complete([value])` or
  `completeError(error, [stackTrace])`. Completing twice throws
  `StateError` (plain `Completer` semantics).
* `EmitFutureOrController(value: v)` is completed at construction;
  `EmitFutureOrController<T?>(nullValue: true)` completes with `null`
  (`value` wins over `nullValue`). `EmitFutureOr.withValue(v)` is the
  shortcut for an immediate non-null value; do not pass `null` to it (it
  would stay pending), build a controller with `nullValue: true` instead.
* `cancel({reason})` completes a pending controller with
  `EmitCancelException(reason)` and sets `isCancelled`; it is safe to call
  at any time and more than once, also after a normal completion (then
  only `isCancelled` changes). `close()` is `cancel(reason: 'closed')` when
  not completed yet: call it when the owner goes away.
* `isCompleted` is true after `complete`, `completeError` or `cancel`;
  check `isCancelled` to tell a cancellation apart.
* Consumer side, `EmitFutureOr<T>`: `toFutureOr()` returns the `T` value
  itself when the controller completed with a value, otherwise the pending
  (or failed) `Future<T>`; test `is Future<T>` before awaiting when you
  want to skip the microtask. `toFuture()` always returns the `Future<T>`.
* `listen(onValue, {onError})` returns an `EmitFutureOrSubscription`. If
  the value is already there `onValue` runs synchronously inside `listen`,
  otherwise when the value arrives. `onError` is called with
  `(error, stackTrace)` or, if that signature fails, with `(error)`.
  `onValue` may be `null`. A controller supports a single listener.
* `subscription.cancel({reason})` cancels the underlying controller (the
  producer sees `isCancelled`); `subscription.asFutureOr()` is the same as
  `toFutureOr()`.
* The completer is synchronous: `then` callbacks and listeners run during
  `complete`/`cancel`, before it returns. Keep them cheap and never call
  `complete` on the same controller from inside one.
* Attach the consumer (`listen` with `onError`, `expectLater`, a `then`
  with error handling) before cancelling a pending controller: cancelling
  a future nobody listens to reports an unhandled `EmitCancelException`
  in the current zone immediately, which fails a `test`.
* `toString()` prints `toDebugModel()` (a `package:cv` `Model` with the
  completer identity, `completed`, `error` and `value`), handy in logs.
* Tests: `dart test` (pure Dart, also fine with `-p chrome`).

## Examples

### Cache handing out values synchronously once loaded

```dart
import 'dart:async';

import 'package:tekartik_app_emit/emit.dart';

/// Loads user names once; a loaded name is returned without a Future.
class UserNameLoader {
  final _controllers = <int, EmitFutureOrController<String>>{};

  EmitFutureOr<String> load(int id) {
    var existing = _controllers[id];
    if (existing != null) {
      return existing.futureOr;
    }
    final controller = _controllers[id] = EmitFutureOrController<String>();
    // Simulate an asynchronous fetch.
    Future<void>.delayed(const Duration(milliseconds: 10), () {
      if (!controller.isCompleted) {
        controller.complete('user_$id');
      }
    });
    return controller.futureOr;
  }

  /// Cancel every pending load, listeners get an EmitCancelException.
  void close() {
    for (var controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

Future<void> main() async {
  var loader = UserNameLoader();
  // First call: pending, toFutureOr() gives a Future.
  var futureOr = loader.load(1).toFutureOr();
  var name = futureOr is Future<String> ? await futureOr : futureOr;
  print(name); // user_1
  // Second call: completed, toFutureOr() gives the String itself.
  print(loader.load(1).toFutureOr()); // user_1
  loader.close();
}
```

### Listen, cancel from the subscription, handle the cancellation

```dart
import 'package:tekartik_app_emit/emit.dart';

Future<void> main() async {
  var controller = EmitFutureOrController<int>();
  var subscription = controller.futureOr.listen(
    (value) => print('got $value'),
    onError: (Object error) {
      if (error is EmitCancelException) {
        print('cancelled: ${error.reason}');
      }
    },
  );

  // Nobody answered in time: give up from the consumer side.
  subscription.cancel(reason: 'timeout');
  print(controller.isCancelled); // true
  print(controller.isCompleted); // true

  // No value: reading it throws.
  try {
    await subscription.asFutureOr();
  } on EmitCancelException catch (e) {
    print(e); // Emit cancelled due to: timeout
  }
}
```

### Unit test of the synchronous semantics

```dart
import 'package:tekartik_app_emit/emit.dart';
import 'package:test/test.dart';

void main() {
  test('value is available synchronously once completed', () async {
    var controller = EmitFutureOrController<int>();
    expect(controller.isCompleted, isFalse);
    expect(controller.futureOr.toFutureOr(), isA<Future<int>>());

    var completed = false;
    var future = controller.futureOr.toFuture().then((_) => completed = true);
    controller.complete(1);
    expect(completed, isTrue); // sync completer
    expect(controller.futureOr.toFutureOr(), 1);
    await future;

    expect(EmitFutureOr<int>.withValue(2).toFutureOr(), 2);
  });

  test('cancel completes with EmitCancelException', () async {
    var controller = EmitFutureOrController<void>();
    // Listen before cancelling, the error is reported synchronously.
    var check = expectLater(
      controller.futureOr.toFuture(),
      throwsA(isA<EmitCancelException>()),
    );
    controller.cancel(reason: 'test');
    expect(controller.isCancelled, isTrue);
    await check;
  });
}
```
