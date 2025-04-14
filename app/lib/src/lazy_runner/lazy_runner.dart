import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';

/// index the number of times the function is called
///
/// Starts at 0. count matches index + 1 before the start of the action
/// Could be ignored, but potentially useful for debugging
typedef LazyRunnerFunction<T> = Future<T> Function(int index);

/// Turn on debug
const bool debugLazyRunner = false; // devWarning(true);

/// Lazy runner private extension
@visibleForTesting
extension LazyRunnerPrvExtension on LazyRunner {
  _LazyRunner get _self => this as _LazyRunner;
  bool get _locked => _self._lock.locked;

  /// Is the action running
  bool get isRunning => _locked && _self._lockedIsTriggered;

  /// Is the action triggered
  bool get isTriggered => _locked && _self._triggerCompleter.isCompleted;
}

/// Lazy runner extension
extension LazyRunnerExtension on LazyRunner {
  /// Count of action ran, updated before the action
  int get count => _self.count;

  /// Is the runner disposed
  bool get disposed => _self._disposed;
}

/// Lazy runner
abstract class LazyRunner<T> {
  /// Trigger the action
  void trigger();

  /// Trigger the action and wait for it to finish and returns its future (error or success)
  Future<T> triggerAndWait();

  /// Create a lazy runner controller
  factory LazyRunner({required LazyRunnerFunction<T> action}) =>
      _LazyRunner<T>(action: action);

  /// Create a lazy runner controller
  /// First action is run after duration, simple call trigger() to call it right away
  factory LazyRunner.periodic({
    required Duration duration,
    required LazyRunnerFunction<T> action,
  }) => _PeriodicLazyRunner<T>(duration: duration, action: action);

  /// Wait for current action to finish or returns the last result
  Future<T?> waitCurrent();

  /// Wait for current and triggered action to finish
  ///
  /// like waitCurrent if never ran
  Future<T?> waitTriggered();

  /// dispose and wait for current action to finish
  Future<void> close();

  /// Get the last result
  T? get lastResult;

  /// Dispose, current action might terminate later
  void dispose();
}

void _log(Object? message) {
  // ignore: avoid_print
  print('/LazyRunner $message');
}

class _PeriodicLazyRunner<T> extends _LazyRunner<T> {
  final Duration duration;

  @override
  Future<void> _waitForTrigger() async {
    try {
      await super._waitForTrigger().timeout(duration);
    } on TimeoutException catch (_) {
      if (_debug) {
        _log('duration timeout $duration');
      }
    }
  }

  _PeriodicLazyRunner({required this.duration, required super.action});
}

typedef _ActionCompleter<T> = Completer<T?>;

/// Lazy runner
class _LazyRunner<T> implements LazyRunner<T> {
  bool get _debug => debugLazyRunner;

  int count = 0;

  final LazyRunnerFunction<T> action;

  var _disposed = false;

  final _lock = Lock();
  var _triggerCompleter = Completer<void>();
  final _actionCompleters = <_ActionCompleter<T>>[];

  /// Saved last result
  T? _lastResult;

  void _completeActionResult(T? result) {
    for (var actionCompleter in _actionCompleters) {
      actionCompleter.complete(result);
    }
    _actionCompleters.clear();
  }

  void _completeActionError(Object error) {
    for (var actionCompleter in _actionCompleters) {
      actionCompleter.completeError(error);
    }
    _actionCompleters.clear();
  }

  /// Trigger the action
  @override
  void trigger() {
    _trigger();
  }

  /// Trigger the action

  Future<void> _trigger() async {
    if (_debug) {
      _log('manual trigger');
    }
    await _lock.synchronized(() async {
      _triggerCompleter.safeComplete();
    });
  }

  Future<T?> _callAction() async {
    return await _lock.synchronized(() async {
      /// Create new trigger now!
      _triggerCompleter = Completer<void>();
      if (_disposed) {
        _completeActionError(StateError('disposed'));
        return null;
      }
      var actionIndex = count++;
      if (_debug) {
        _log('start action $actionIndex');
      }
      try {
        /// Save last result
        var result = _lastResult = await action(actionIndex);
        _completeActionResult(result);
        return result;
      } catch (e) {
        _completeActionError(e);
        rethrow;
      } finally {
        if (_debug) {
          _log('end action $actionIndex');
        }
      }
    });
  }

  /// Wait for the trigger to be done
  Future<void> _waitForTrigger() async {
    if (_debug) {
      _log('wait trigger');
    }
    await _triggerCompleter.future;

    if (_debug) {
      _log('triggered');
    }
  }

  /// Create a lazy runner controller
  _LazyRunner({required this.action}) {
    () async {
      while (!_disposed) {
        await _waitForTrigger();
        try {
          await _callAction();
        } catch (e, st) {
          if (_debug || isDebug) {
            // ignore: avoid_print
            print('/LazyRunner: error in triggered action $count $e');
            if (debugLazyRunner) {
              // ignore: avoid_print
              print(st);
            }
          }
        }
      }
    }();
  }

  /// Dispose (prefer close)
  @override
  void dispose() {
    if (_debug) {
      _log('dispose');
    }
    _disposed = true;
    _lock.synchronized(() async {
      _triggerCompleter.safeComplete();
    });
  }

  /// Dispose
  @override
  Future<void> close() async {
    if (_debug) {
      _log('close');
    }
    _disposed = true;

    await _lock.synchronized(() async {
      _triggerCompleter.safeComplete();
    });
  }

  @override
  Future<T> triggerAndWait() async {
    if (_debug) {
      _log('manual trigger');
    }
    var completer = _ActionCompleter<T>();
    await _lock.synchronized(() async {
      _triggerCompleter.safeComplete();
      _actionCompleters.add(completer);
    });

    /// T might be nullable so don't use `!` here
    return (await completer.future) as T;
  }

  @override
  Future<T?> waitCurrent() async {
    await _lock.synchronized(() async {});
    return _lastResult;
  }

  bool get _lockedIsTriggered => _triggerCompleter.isCompleted && !_disposed;

  _ActionCompleter<T> _newActionCompleter() {
    var completer = _ActionCompleter<T>();
    return completer;
  }

  /// Throws if never ran.
  @override
  Future<T?> waitTriggered() async {
    var completer = _newActionCompleter();
    await _lock.synchronized(() async {
      if (_lockedIsTriggered) {
        _actionCompleters.add(completer);
      } else {
        // If never ran yet
        // No trigger yet
        completer.complete(_lastResult);
      }
    });
    return await completer.future;
  }

  @override
  T? get lastResult => _lastResult;
}
