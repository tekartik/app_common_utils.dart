# tekartik_app_rx_bloc

Base classes for a bloc (or controller) publishing its state as an
[rxdart](https://pub.dev/packages/rxdart) `ValueStream`, on top of
`BaseBloc` of `tekartik_app_bloc`, with automatic disposal of the subjects,
subscriptions and inner blocs it creates (`AutoDispose` of
`tekartik_app_rx`).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_rx_bloc:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_rx_bloc
```

```dart
import 'package:tekartik_app_rx_bloc/auto_dispose_state_base_bloc.dart';

class CounterBloc extends AutoDisposeStateBaseBloc<int> {
  CounterBloc() {
    // No initial value until the first add.
    add(0);
  }

  void increment() {
    if (disposed) return;
    add(state.value + 1);
  }
}

Future<void> main() async {
  var bloc = CounterBloc();
  var subscription = bloc.state.listen((count) => print('count: $count'));
  bloc.increment();
  await Future<void>.delayed(Duration.zero);
  await subscription.cancel();
  // Closes the state and everything registered with audiAdd*.
  bloc.dispose();
}
```

Pure Dart: Dart VM, browser, Flutter. See [example/main.dart](example/main.dart).

## What to use

* `StateBaseBloc<T>` (`state_base_bloc.dart`, re-exports rxdart): one state,
  `add(state)`, `addError(error)`, `ValueStream<T> get state`, `dispose()`.
* `AutoDisposeStateBaseBloc<T>` (`auto_dispose_state_base_bloc.dart`): the
  same, plus `audiAddBehaviorSubject`, `audiAddStreamSubscription`,
  `audiAddStreamController`, `audiAddDisposable(innerBloc)`... all disposed by
  `dispose()`.
* `AutoDisposeBaseBloc` (`auto_dispose_base_bloc.dart`): no single state,
  several subjects.

## Common pitfalls

* The state has no initial value: `state.value` throws a `ValueStreamError`
  before the first `add`; add one in the constructor or read `valueOrNull`.
* `add` after `dispose()` throws a `StateError`: check `disposed` after an
  `await`.
* Overriding `dispose()`: call `super.dispose()`.

## Agent skills

[skills/tekartik-app-rx-bloc-base](skills/tekartik-app-rx-bloc-base/SKILL.md).
