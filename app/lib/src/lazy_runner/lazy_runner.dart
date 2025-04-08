import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';

/// Count the number of times the function is called
/// Could be ignored, but potentially useful for debugging
typedef LazyRunnerFunction<T> = Future<T?> Function(int count);

/// Turn on debug
bool debugLazyRunner = false; // devWarning(true);

/// Lazy runner extension
extension LazyRunnerExtension on LazyRunner {
  /// Count of action ran
  @visibleForTesting
  int get count => (this as _LazyRunner).count;
}

/// Lazy runner
abstract class LazyRunner<T> {
  /// Trigger the action
  void trigger();

  /// Trigger the action and wait for it to finish and returns its future (error or success)
  Future<void> triggerAndWait();

  /// Create a lazy runner controller
  factory LazyRunner({required LazyRunnerFunction<T> action}) =>
      _LazyRunner<T>(action: action);

  /// Create a lazy runner controller
  /// First action is run after duration, simple call trigger() to call it right away
  factory LazyRunner.periodic({
    required Duration duration,
    required LazyRunnerFunction<T> action,
  }) => _PeriodicLazyRunner<T>(duration: duration, action: action);

  /// dispose and wait for current action to finish
  Future<void> close();

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
  Future<void> _waitTrigger() async {
    try {
      await super._waitTrigger().timeout(duration);
    } on TimeoutException catch (_) {
      if (_debug) {
        _log('duration timeout $duration');
      }
    }
  }

  _PeriodicLazyRunner({required this.duration, required super.action});
}

/// Lazy runner
class _LazyRunner<T> implements LazyRunner<T> {
  bool get _debug => debugLazyRunner;

  int count = 0;

  final LazyRunnerFunction<T> action;

  var _disposed = false;
  final _lock = Lock();
  var _triggerCompleter = Completer<void>();
  final _actionCompleters = <Completer<T?>>[];

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
      if (_disposed) {
        _completeActionResult(null);
        return null;
      }
      var actionIndex = count++;
      if (_debug) {
        _log('start action $actionIndex');
      }
      try {
        var result = await action(actionIndex);
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

  Future<void> _waitTrigger() async {
    if (_debug) {
      _log('wait trigger');
    }
    await _triggerCompleter.future;

    if (_debug) {
      _log('triggered');
    }
    _triggerCompleter = Completer<void>();
  }

  /// Create a lazy runner controller
  _LazyRunner({required this.action}) {
    () async {
      while (!_disposed) {
        await _waitTrigger();
        try {
          await _callAction();
        } catch (e) {
          if (_debug || isDebug) {
            // ignore: avoid_print
            print('/LazyRunner: error in triggered action $count $e');
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
  Future<T?> triggerAndWait() async {
    if (_debug) {
      _log('manual trigger');
    }
    var completer = Completer<T?>();
    await _lock.synchronized(() async {
      _triggerCompleter.safeComplete();
      _actionCompleters.add(completer);
    });
    return await completer.future;
  }
}
