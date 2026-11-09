# tekartik_app_bloc

`BaseBloc`, the tiny base class of the blocs (or controllers) of the
Tekartik apps: a `dispose()` to override and a `disposed` getter to check
after an `await`. Plain Dart, no Flutter and no bloc framework.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_bloc:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_bloc
```

```dart
import 'dart:async';

import 'package:tekartik_app_bloc/base_bloc.dart';

class CounterBloc extends BaseBloc {
  final _controller = StreamController<int>.broadcast();
  Stream<int> get counts => _controller.stream;

  @override
  void dispose() {
    unawaited(_controller.close()); // own resources first
    super.dispose();
  }
}

void main() {
  var bloc = CounterBloc();
  bloc.dispose();
  print(bloc.disposed); // true
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser. See
[example/main.dart](example/main.dart).

## Common pitfalls

* `BaseBloc` closes nothing by itself: close your controllers and cancel
  your subscriptions in `dispose()` (or use the `AutoDisposeMixin` of
  `tekartik_app_common_utils`).
* An override must call `super.dispose()` (`@mustCallSuper`), otherwise
  `disposed` stays false.
* After an `await`, check `disposed` before adding to a stream controller:
  it may be closed.
* `dispose()` returns `void`: start async cleanup with `unawaited(...)`.

## Agent skills

[skills/tekartik-app-bloc-base](skills/tekartik-app-bloc-base/SKILL.md).
