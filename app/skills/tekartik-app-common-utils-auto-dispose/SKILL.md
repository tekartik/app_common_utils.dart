---
name: tekartik-app-common-utils-auto-dispose
description: >-
  Use when a controller, bloc, service or widget state must release stream
  subscriptions, controllers and other resources in one call with
  tekartik_app_common_utils: AutoDisposeMixin, AutoDispose, audiAdd,
  audiAddSelf, audiAddFunction, audiAddStreamSubscription,
  audiAddStreamController, audiAddDisposable, audiDispose,
  audiDisposeFunction, audiDisposeAll, AutoDisposable, AutoDisposableMixin,
  AutoDisposerable, AutoDisposerableBase and the auto_dispose.dart import.
---

# Auto dispose (tekartik_app_common_utils)

`auto_dispose.dart` is a tiny ownership helper: an object registers everything
it creates (`audi*` methods) and releases all of it in one `audiDisposeAll()`
call. It is pure Dart, so the same code works in a Flutter `State`, in a bloc
or in a plain server class.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_common_utils:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app
  ```
* Import `package:tekartik_app_common_utils/auto_dispose.dart`. It exports
  `AutoDispose`, `AutoDisposeMixin`, `AutoDisposeDisposableExt`,
  `AutoDisposable`, `AutoDisposableMixin`, `AutoDisposerable`,
  `AutoDisposerableBase` and the `AutoDisposeFunction` /
  `AutoDisposeSelfFunction<T>` typedefs.
* Add `with AutoDisposeMixin` to the owner class (it implements `AutoDispose`),
  then register in the constructor / init and call `audiDisposeAll()` exactly
  once in `dispose()` / `close()`.
* Registration methods, all returning the object so they can wrap an
  initializer:
  * `audiAddStreamSubscription(sub)` - disposes with `sub.cancel()`.
  * `audiAddStreamController(controller)` - disposes with `controller.close()`.
  * `audiAdd(object, disposeFunction)` - any object plus a closure.
  * `audiAddSelf(object, (o) => ...)` - same, but the closure receives the
    object (call it on a class typed as `AutoDisposeMixin` so `T` is inferred).
  * `audiAddDisposable(disposable)` - for an `AutoDisposable`, disposes with
    `selfDispose()` (extension `AutoDisposeDisposableExt` on `AutoDispose`).
  * `audiAddFunction(fn)` - a bare cleanup closure with no owning object.
* Release early when needed: `audiDispose(object)` runs and forgets the
  disposer of that one object (null is ignored, so
  `audiDispose(_maybeSub)` is safe); `audiDisposeFunction(fn)` does the same
  for a function registered with `audiAddFunction`. Both are no-ops if the
  entry was already disposed, which makes re-subscription loops safe.
* Objects are keyed by identity in a map: registering the *same* object twice
  replaces the first disposer. Register each subscription/controller instance
  once.
* Implement `AutoDisposable` (a single `void selfDispose()`) on anything a
  parent should be able to dispose; `AutoDisposableMixin` gives a no-op
  implementation for leaf classes that have nothing to release.
* For a class that both owns resources and is owned by a parent, extend
  `AutoDisposerableBase` (it mixes `AutoDisposeMixin` + `AutoDisposableMixin`
  and its `selfDispose()` calls `audiDisposeAll()`). Override `selfDispose()`
  only with `super.selfDispose()` called (it is `@mustCallSuper`).
  `AutoDisposerable` is the matching interface (`AutoDispose` +
  `AutoDisposable`) to use in signatures.
* Anti-patterns: calling `audiDisposeAll()` twice and expecting the second
  call to re-dispose (the registry is cleared); keeping a manual
  `_subscription?.cancel()` next to `audiAddStreamSubscription` (do one or the
  other); registering an object created in `build()`.
* In tests, assert disposal by registering a flag-setting closure and checking
  it after `audiDisposeAll()`; see `test/auto_dispose_test.dart` in the
  package.

## Examples

### A controller owning a subscription and a controller

```dart
import 'dart:async';

import 'package:tekartik_app_common_utils/auto_dispose.dart';

class CounterController with AutoDisposeMixin {
  late final StreamController<int> _controller;
  var _count = 0;

  CounterController(Stream<void> ticks) {
    _controller = audiAddStreamController(StreamController<int>.broadcast());
    audiAddStreamSubscription(
      ticks.listen((_) {
        _controller.add(++_count);
      }),
    );
    audiAddFunction(() {
      print('counter closed at $_count');
    });
  }

  Stream<int> get counts => _controller.stream;

  void close() => audiDisposeAll();
}
```

### Owning a plain object and releasing it early

```dart
import 'dart:async';

import 'package:tekartik_app_common_utils/auto_dispose.dart';

class Connection {
  Future<void> disconnect() async {}
}

class Session with AutoDisposeMixin {
  Connection? _connection;

  void connect() {
    // Drop the previous one first, then own the new one.
    audiDispose(_connection);
    _connection = audiAddSelf(Connection(), (connection) {
      unawaited(connection.disconnect());
    });
  }

  void dispose() => audiDisposeAll();
}
```

### Parent/child hierarchy with AutoDisposerableBase

```dart
import 'package:tekartik_app_common_utils/auto_dispose.dart';

class ChildService extends AutoDisposerableBase {
  ChildService() {
    audiAddFunction(() => print('child released'));
  }
}

class ParentService extends AutoDisposerableBase {
  late final ChildService child = audiAddDisposable(ChildService());

  @override
  void selfDispose() {
    print('parent releasing');
    super.selfDispose(); // disposes child too
  }
}

void main() {
  var parent = ParentService();
  print(parent.child);
  parent.selfDispose();
}
```

### Flutter-style usage (the mixin is plain Dart)

```dart
import 'dart:async';

import 'package:tekartik_app_common_utils/auto_dispose.dart';

/// Stand-in for a widget State: same pattern, `initState` / `dispose`.
class MyScreenState with AutoDisposeMixin {
  void initState(Stream<String> messages) {
    audiAddStreamSubscription(messages.listen(print));
  }

  void dispose() {
    audiDisposeAll();
  }
}
```
