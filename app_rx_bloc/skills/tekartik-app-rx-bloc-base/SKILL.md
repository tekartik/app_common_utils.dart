---
name: tekartik-app-rx-bloc-base
description: >-
  Use when writing a bloc/controller that exposes its state as an rxdart stream
  with tekartik_app_rx_bloc: StateBaseBloc<T> (state ValueStream, add, addError,
  dispose, disposed), AutoDisposeBaseBloc and AutoDisposeStateBaseBloc<T> which
  mix AutoDisposeMixin/AutoDisposableMixin so audiAddBehaviorSubject,
  audiAddStreamSubscription, audiAddStreamController, audiAddDisposable and
  audiAddBroadcastValueStream are cleaned up by a single dispose(), from
  package:tekartik_app_rx_bloc/state_base_bloc.dart,
  auto_dispose_base_bloc.dart and auto_dispose_state_base_bloc.dart.
---

# Rx bloc bases (tekartik_app_rx_bloc)

`tekartik_app_rx_bloc` is three small base classes on top of
`tekartik_app_bloc`'s `BaseBloc`: a bloc that publishes one state as a
`ValueStream`, and the same with automatic disposal of every subject,
subscription and inner bloc it created.

## Guidelines

* Not on pub.dev, depend on it through git:
  ```yaml
  dependencies:
    tekartik_app_rx_bloc:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_rx_bloc
      version: '>=0.1.0'
  ```
* Pick one import, each one re-exports what its classes need:
  * `package:tekartik_app_rx_bloc/state_base_bloc.dart` - `StateBaseBloc` plus
    the whole of `rxdart` (`BehaviorSubject`, `ValueStream`,
    `ValueStreamError`...).
  * `package:tekartik_app_rx_bloc/auto_dispose_base_bloc.dart` -
    `AutoDisposeBaseBloc` plus `package:tekartik_app_rx/auto_dispose.dart`
    (`AutoDispose`, `AutoDisposeMixin`, `AutoDisposable`,
    `AutoDisposeRxExtension`, rxdart).
  * `package:tekartik_app_rx_bloc/auto_dispose_state_base_bloc.dart` -
    `AutoDisposeStateBaseBloc` plus both of the above. This is the usual
    choice.
* `StateBaseBloc<T>` owns a private `BehaviorSubject<T>`: publish with
  `add(state)` / `addError(error, [stackTrace])`, read through
  `ValueStream<T> get state`. There is no seeded value, so `state.hasValue` is
  false and `state.value` throws a `ValueStreamError` until the first `add`:
  use `state.valueOrNull`, or `add(...)` an initial state in the constructor.
* Extend, do not instantiate: `class MyBloc extends
  AutoDisposeStateBaseBloc<MyState> { ... }`. Expose intent methods that call
  `add(...)`; keep `add` itself out of the widget/consumer code.
* `dispose()` closes the state subject and sets `disposed`. Calling `add()`
  afterwards throws a `StateError`, so guard long running work with
  `if (disposed) return;`. `dispose()` is `@mustCallSuper` in the auto dispose
  classes - always call `super.dispose()` when overriding.
* Register everything the bloc creates so one `dispose()` cleans it all:
  `audiAddBehaviorSubject(BehaviorSubject.seeded(...))`,
  `audiAddBroadcastValueStream(...)`, `audiAddStreamSubscription(
  stream.listen(...))`, `audiAddStreamController(controller)`,
  `audiAdd(object, closeFn)`, `audiAddFunction(fn)`. Prefer
  `late final`/`late var` fields so the registration happens on first use.
* A bloc that owns another bloc registers it with `audiAddDisposable(
  InnerBloc())`: `AutoDisposeBaseBloc` and `AutoDisposeStateBaseBloc` implement
  `AutoDisposable` (`selfDispose()` calls `dispose()`), so disposing the outer
  bloc disposes the inner one.
* Use `AutoDisposeBaseBloc` when the bloc has several streams/subjects and no
  single "state", `AutoDisposeStateBaseBloc<T>` when it has one. Plain
  `StateBaseBloc<T>` only when nothing else must be disposed.
* Pure Dart (VM, web, Flutter). In Flutter, call `bloc.dispose()` from the
  `State.dispose()` (or the provider disposer) that created it.
* See also `tekartik-app-bloc-base`
  for `BaseBloc` itself and
  `tekartik-app-rx-streams`
  for `toBroadcastValueStream()` and the auto dispose rx extension.
* Anti-patterns: exposing the `BehaviorSubject` instead of the `ValueStream`;
  reading `state.value` before the first `add`; creating subjects or
  subscriptions without `audiAdd*`; forgetting `super.dispose()`; adding a
  state after `dispose()`.

## Examples

### A state bloc

```dart
import 'package:tekartik_app_rx_bloc/state_base_bloc.dart';

class CounterState {
  final int count;

  CounterState(this.count);
}

class CounterBloc extends StateBaseBloc<CounterState> {
  CounterBloc() {
    // No seeded value: publish the initial state explicitly.
    add(CounterState(0));
  }

  void increment() {
    if (disposed) return;
    add(CounterState(state.value.count + 1));
  }

  void fail() => addError(StateError('boom'));
}

Future<void> main() async {
  var bloc = CounterBloc();
  var subscription = bloc.state.listen(
    (state) => print('count: ${state.count}'),
    onError: (Object error) => print('error: $error'),
  );
  bloc.increment();
  print(bloc.state.value.count); // 1
  print(bloc.state.valueOrNull?.count); // 1, null safe read

  await subscription.cancel();
  bloc.dispose();
  print(bloc.disposed); // true
}
```

### Auto disposed state bloc with a subscription

```dart
import 'dart:async';

import 'package:tekartik_app_rx_bloc/auto_dispose_state_base_bloc.dart';

/// Recomputes its state from an external stream.
class SearchBloc extends AutoDisposeStateBaseBloc<List<String>> {
  final StreamController<String> _queryController;

  SearchBloc(Stream<String> queries)
    : _queryController = StreamController<String>() {
    audiAddStreamController(_queryController);
    audiAddStreamSubscription(
      queries.listen((query) {
        if (disposed) return;
        add(_search(query));
      }),
    );
    add(<String>[]);
  }

  List<String> _search(String query) =>
      query.isEmpty ? <String>[] : ['$query 1', '$query 2'];

  // No dispose() override needed: the inherited one runs audiDisposeAll()
  // (closing the controller and cancelling the subscription) and closes the
  // state subject. When you do override it, call super.dispose().
}

Future<void> main() async {
  var controller = StreamController<String>();
  var bloc = SearchBloc(controller.stream);
  controller.add('dart');
  await Future<void>.delayed(Duration.zero);
  print(bloc.state.value); // [dart 1, dart 2]
  bloc.dispose();
  await controller.close();
}
```

### Several subjects and a nested bloc

```dart
import 'package:tekartik_app_rx_bloc/auto_dispose_base_bloc.dart';

class ProfileBloc extends AutoDisposeBaseBloc {
  /// Registered on first access, closed by dispose().
  late final loading = audiAddBehaviorSubject(BehaviorSubject.seeded(false));
  late final name = audiAddBehaviorSubject(BehaviorSubject<String>.seeded(''));

  Future<void> load() async {
    loading.add(true);
    try {
      name.add('alex');
    } finally {
      if (!disposed) {
        loading.add(false);
      }
    }
  }
}

class AppBloc extends AutoDisposeBaseBloc {
  /// Disposing this bloc disposes the inner one.
  late final profile = audiAddDisposable(ProfileBloc());
}

Future<void> main() async {
  var app = AppBloc();
  await app.profile.load();
  print(app.profile.name.value); // alex
  app.dispose();
  print(app.profile.disposed); // true
  print(app.profile.name.isClosed); // true
}
```
