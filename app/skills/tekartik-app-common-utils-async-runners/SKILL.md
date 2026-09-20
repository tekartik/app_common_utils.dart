---
name: tekartik-app-common-utils-async-runners
description: >-
  Use when coalescing repeated async work (refresh, save, sync, reload) into a
  single non-overlapping execution with tekartik_app_common_utils: LazyRunner,
  LazyRunner.periodic, trigger, triggerAndWait, waitCurrent, waitTriggered,
  lastResult, LazyRunnerExtension count/disposed, debugLazyRunner, and
  SingleFlight with run, wait, waitOrRun, close - imports lazy_runner.dart and
  single_flight.dart.
---

# Lazy runner and single flight (tekartik_app_common_utils)

Two small controllers that serialize a repeated async action so it never runs
twice at the same time. `LazyRunner` is fire-and-forget (trigger now, the
action runs in the background, optionally on a period); `SingleFlight`
deduplicates awaited calls and keeps the last result.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_common_utils:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app
  ```
* Imports: `package:tekartik_app_common_utils/lazy_runner.dart` (exports
  `LazyRunner`, `LazyRunnerFunction<T>`, `LazyRunnerExtension`,
  `debugLazyRunner`) and
  `package:tekartik_app_common_utils/single_flight.dart` (exports
  `SingleFlight`).

### LazyRunner

* Create with `LazyRunner<T>(action: (index) async { ... })`: the action
  receives the 0-based run index. `LazyRunner<T>.periodic(duration: ...,
  action: ...)` runs the action every `duration` even without a trigger, and
  `trigger()` still runs it right away.
* `trigger()` returns immediately and requests one run; several triggers while
  a run is in progress collapse into a single extra run. Errors thrown by the
  action are swallowed by the background loop (printed in debug), so handle
  them inside the action or use `triggerAndWait()`.
* `await triggerAndWait()` returns the result of the run it triggered, and
  rethrows the action error - use it when the caller must see the outcome.
* `await waitCurrent()` waits for a run already in progress and returns
  `lastResult` (null if it never ran); `await waitTriggered()` also waits for
  a pending trigger. Neither starts a run.
* `lastResult` is the last successful value; `count` (from
  `LazyRunnerExtension`) is the number of runs started; `disposed` tells
  whether it was closed.
* `await close()` stops the loop and waits for the in-flight run; `dispose()`
  is the non-awaiting variant. Pending `triggerAndWait()` futures then complete
  with a `StateError('disposed')`; do not trigger a closed runner.
* `debugLazyRunner` is a compile-time `const false` flag in the package
  sources; it cannot be set at runtime - edit it only when debugging the
  package itself.

### SingleFlight

* Create with `SingleFlight<T>(() async => ...)`, one instance per logical
  operation, and keep it alive.
* `run()` always guarantees a fresh execution *after* the call: while an
  execution is in flight, the first extra `run()` schedules exactly one
  follow-up run and every later `run()` before it starts returns that same
  future. So two concurrent `run()` calls yield two executions, ten yield two.
* `wait()` never starts anything: it returns the in-flight (or scheduled)
  future, else the last result, else `null`.
* `waitOrRun()` returns the last/in-flight result and only runs when there is
  none - the read-through cache accessor.
* `await close()` waits for pending work; `run()` after `close()` throws a
  `StateError`.
* Anti-patterns: creating a `SingleFlight` or `LazyRunner` per call (defeats
  the deduplication); using `LazyRunner.trigger()` when the caller needs the
  result or the error; forgetting `close()` on a periodic runner (its loop
  keeps the isolate alive in tests).

## Examples

### Coalesced save with LazyRunner

```dart
import 'package:tekartik_app_common_utils/lazy_runner.dart';

class Document {
  var _text = '';
  late final LazyRunner<void> _saver = LazyRunner<void>(
    action: (index) async {
      print('save #$index: $_text');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    },
  );

  /// Many edits in a row trigger a single extra save.
  void edit(String text) {
    _text = text;
    _saver.trigger();
  }

  Future<void> close() async {
    await _saver.triggerAndWait();
    await _saver.close();
  }
}

Future<void> main() async {
  var doc = Document()
    ..edit('a')
    ..edit('ab')
    ..edit('abc');
  await doc.close();
}
```

### Periodic refresh, with a manual kick

```dart
import 'package:tekartik_app_common_utils/lazy_runner.dart';

Future<void> main() async {
  var runner = LazyRunner<int>.periodic(
    duration: const Duration(seconds: 30),
    action: (index) async {
      print('refresh $index');
      return index;
    },
  );
  // Refresh now instead of waiting 30s, and wait for the value.
  var value = await runner.triggerAndWait();
  print('got $value (count: ${runner.count}, last: ${runner.lastResult})');
  await runner.close();
  print('disposed: ${runner.disposed}');
}
```

### Deduplicated fetch with SingleFlight

```dart
import 'package:tekartik_app_common_utils/single_flight.dart';

class ConfigLoader {
  var _httpCalls = 0;
  late final SingleFlight<Map<String, Object?>> _flight =
      SingleFlight<Map<String, Object?>>(() async {
        _httpCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return <String, Object?>{'version': _httpCalls};
      });

  /// Cached: loads once, then reuses the result.
  Future<Map<String, Object?>> get() => _flight.waitOrRun();

  /// Forces a reload, sharing it with concurrent callers.
  Future<Map<String, Object?>> reload() => _flight.run();

  Future<void> close() => _flight.close();
}

Future<void> main() async {
  var loader = ConfigLoader();
  await Future.wait([loader.get(), loader.get(), loader.get()]);
  print(await loader.reload());
  await loader.close();
}
```

### Peeking at the current state without triggering

```dart
import 'package:tekartik_app_common_utils/single_flight.dart';

Future<void> main() async {
  var flight = SingleFlight<int>(() async => 42);
  print(await flight.wait()); // null: never ran
  print(await flight.run()); // 42
  print(await flight.wait()); // 42, no new execution
  await flight.close();
}
```
