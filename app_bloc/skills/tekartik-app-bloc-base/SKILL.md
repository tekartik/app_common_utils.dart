---
name: tekartik-app-bloc-base
description: >-
  Use when writing a bloc/controller class in a Tekartik app that needs a
  minimal disposable base with tekartik_app_bloc: BaseBloc, its @mustCallSuper
  dispose() method, the disposed getter and the
  package:tekartik_app_bloc/base_bloc.dart import.
---

# BaseBloc (tekartik_app_bloc)

`tekartik_app_bloc` is deliberately tiny: a single `BaseBloc` class that
tracks whether `dispose()` has been called. It is the common base for the
blocs/controllers of Tekartik apps, so that UI code can depend on one
lifecycle contract without pulling in Flutter or a bloc framework.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_bloc/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_bloc:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_bloc
  ```
* Single import and single public API:
  `import 'package:tekartik_app_bloc/base_bloc.dart';` exposes
  `class BaseBloc` with `void dispose()` (marked `@mustCallSuper`) and
  `bool get disposed`.
* Extend `BaseBloc` for any object with a lifetime tied to a screen, a route
  or a session: stream controllers, subscriptions, timers, open connections.
* Always call `super.dispose()` from an override - `@mustCallSuper` makes the
  analyzer report it otherwise, and skipping it leaves `disposed` false
  forever. Dispose your own resources first, then call `super.dispose()`.
* Use `disposed` as a guard in async continuations: after an `await`, the
  screen may be gone, so `if (disposed) return;` before touching a controller
  or adding to a stream. It is also the right check before re-entering
  `dispose()`, which is safe but pointless twice.
* `BaseBloc` does not close anything for you: it has no registry of
  resources. Cancel subscriptions and close controllers explicitly in
  `dispose()`, or mix in the `audi*` helpers from
  `tekartik_app_common_utils` (`auto_dispose.dart`) when a class owns many
  resources.
* In Flutter, create the bloc in `initState` (or in a provider) and call
  `dispose()` from the widget `State.dispose()` / provider disposal. Never
  create one in `build()`.
* Expose state as broadcast streams plus a last-value getter; keep widgets
  free of business logic. Blocs are plain Dart, so they can be unit tested
  with `package:test` alone (see `test/base_bloc_test.dart`).
* Anti-patterns: adding events to a closed `StreamController` after
  `dispose()` (check `disposed`); making `dispose()` async - it returns
  `void`, so start async cleanup with `unawaited(...)` or expose a separate
  `close()`; reusing a bloc after disposal instead of creating a new one.

## Examples

### A bloc owning a stream controller

```dart
import 'dart:async';

import 'package:tekartik_app_bloc/base_bloc.dart';

class CounterBloc extends BaseBloc {
  final _controller = StreamController<int>.broadcast();
  var _count = 0;

  Stream<int> get counts => _controller.stream;
  int get count => _count;

  void increment() {
    if (disposed) {
      return;
    }
    _controller.add(++_count);
  }

  @override
  void dispose() {
    unawaited(_controller.close());
    super.dispose();
  }
}

Future<void> main() async {
  var bloc = CounterBloc();
  bloc.counts.listen(print);
  bloc.increment();
  await Future<void>.delayed(Duration.zero);
  bloc.dispose();
  print(bloc.disposed); // true
}
```

### Guarding async work with `disposed`

```dart
import 'dart:async';

import 'package:tekartik_app_bloc/base_bloc.dart';

class ProfileBloc extends BaseBloc {
  final _name = StreamController<String>.broadcast();
  StreamSubscription<void>? _subscription;

  Stream<String> get name => _name.stream;

  Future<void> load(Future<String> Function() fetch) async {
    var value = await fetch();
    // The screen may have been closed while fetching.
    if (disposed) {
      return;
    }
    _name.add(value);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_name.close());
    super.dispose();
  }
}
```

### Unit testing a bloc

```dart
import 'package:tekartik_app_bloc/base_bloc.dart';
import 'package:test/test.dart';

class TestBloc extends BaseBloc {
  var cleaned = false;

  @override
  void dispose() {
    cleaned = true;
    super.dispose();
  }
}

void main() {
  test('dispose', () {
    var bloc = TestBloc();
    expect(bloc.disposed, isFalse);
    bloc.dispose();
    expect(bloc.cleaned, isTrue);
    expect(bloc.disposed, isTrue);
  });
}
```
