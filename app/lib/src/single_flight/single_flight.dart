import 'package:tekartik_app_common_utils/common_utils_import.dart';

/// Single flight
abstract class SingleFlight<T> {
  /// Single flight
  factory SingleFlight(Future<T> Function() action) => _SingleFlight<T>(action);

  /// Execute the action.
  ///
  /// If an action is already running, this will schedule a new run after the current one finishes
  /// (if one is not already scheduled).
  Future<T> run();

  /// Wait for current execution if running, or return the last result. null if never ran.
  Future<T?> wait();

  /// Ensure a result is available.
  ///
  /// If never ran returns trigger a run.
  Future<T> waitOrRun();

  /// Close the single flight and release resources. After this, the instance should not be used.
  Future<void> close();
}

/// Single flight
class _SingleFlight<T> implements SingleFlight<T> {
  final Future<T> Function() _action;
  final _lock = Lock();

  T? _lastResult;
  bool _hasResult = false;
  int? _lastRunTimestamp;

  // Auto-increment global timestamp
  int _globalTimestamp = 0;

  // Current running futures (helper to know if we are running)
  Future<T>? _currentFuture;
  // Next scheduled future
  Future<T>? _nextFuture;

  // Max timestamp requested for the next run
  int? _nextRunTimestamp;

  /// Single flight
  _SingleFlight(this._action);

  int _now() {
    return ++_globalTimestamp;
  }

  /// Execute the action.
  ///
  /// If an action is already running, this will schedule a new run after the current one finishes
  /// (if one is not already scheduled).
  ///
  /// [timestamp] allows forcing a specific timestamp version. Default is auto-increment.
  @override
  Future<T> run() => _run();

  /// Execute the action.
  ///
  /// If an action is already running, this will schedule a new run after the current one finishes
  /// (if one is not already scheduled).
  ///
  /// [timestamp] allows forcing a specific timestamp version. Default is auto-increment.
  Future<T> _run({int? timestamp}) {
    if (_closing) {
      throw StateError('Cannot run after close');
    }

    var ts = timestamp ?? _now();

    // If we have a next future scheduled, update its timestamp requirements and return it
    if (_nextFuture != null) {
      if (_nextRunTimestamp == null || ts > _nextRunTimestamp!) {
        _nextRunTimestamp = ts;
      }
      return _nextFuture!;
    }

    /// Handle last run timestamp:
    if (_lastRunTimestamp != null && ts <= _lastRunTimestamp!) {
      if (_hasResult) {
        return Future.value(_lastResult);
      }
      if (_currentFuture != null) {
        return _currentFuture!;
      }
    }

    // Prepare the future for this run
    var completer = Completer<T>();
    var future = completer.future;

    // Use lock to serialize execution
    // If locked, we are queuing up
    if (_lock.locked) {
      _nextFuture = future;
      _nextRunTimestamp = ts;
    } else {
      _currentFuture = future;
    }

    // ignore: unawaited_futures
    _lock.synchronized(() async {
      // If we were the next future, we are now the current one
      if (_nextFuture == future) {
        _nextFuture = null;
        _currentFuture = future;
      }

      // Determine effective timestamp for this run
      // It is the max of the requested timestamps for this run
      var effectiveTimestamp = _nextRunTimestamp ?? ts;
      // Reset next timestamp for future runs
      _nextRunTimestamp = null;

      try {
        var result = await _action();
        _lastResult = result;
        _hasResult = true;
        _lastRunTimestamp = effectiveTimestamp;
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      } finally {
        // Clear current if it matches
        if (_currentFuture == future) {
          _currentFuture = null;
        }
      }
    });

    return future;
  }

  /// Wait for current execution if running, or return the last result.
  ///
  /// If [timestamp] is provided, it doesn't wait for that specific timestamp,
  /// but currently just returns the pending execution or last result.
  /// (Refinement: Could wait until _lastRunTimestamp >= timestamp?)
  @override
  Future<T?> wait() => _wait();

  /// Wait for current execution if running, or return the last result.
  ///
  /// If [timestamp] is provided, it doesn't wait for that specific timestamp,
  /// but currently just returns the pending execution or last result.
  /// (Refinement: Could wait until _lastRunTimestamp >= timestamp?)
  Future<T?> _wait() async {
    // Return pending if any (next or current)
    if (_nextFuture != null) {
      return _nextFuture;
    }
    if (_currentFuture != null) {
      return _currentFuture;
    }

    // If provided timestamp is newer than last run, and not running,
    // technically we don't have that result. But API says "wait returns last... null if never run".
    if (_hasResult) {
      return _lastResult;
    }
    return null;
  }

  /// Ensure a result is available valid for at least [timestamp].
  ///
  /// If never ran start execution.
  @override
  Future<T> waitOrRun() async {
    return _waitOrRun();
  }

  /// Ensure a result is available valid for at least [timestamp].
  ///
  /// If never ran start execution.
  Future<T> _waitOrRun({int? timestamp}) async {
    var result = await wait();
    if (result == null) {
      return _run(timestamp: timestamp);
    }
    return result;
  }

  var _closing = false;
  @override
  Future<void> close() async {
    _closing = true;
    await wait();
  }
}

/// Extension for testing to access internal methods and state.
@visibleForTesting
extension SingleFlightTestExtension<T> on SingleFlight<T> {
  _SingleFlight<T> get _impl => this as _SingleFlight<T>;

  /// Execute the action.
  ///
  /// If an action is already running, this will schedule a new run after the current one finishes
  /// (if one is not already scheduled).
  ///
  /// [timestamp] allows forcing a specific timestamp version. Default is auto-increment.
  Future<T> testRun({int? timestamp}) => _impl._run(timestamp: timestamp);

  /// Ensure a result is available valid for at least [timestamp].
  ///
  /// If never ran or [timestamp] is newer than last run, start execution.
  Future<T> testWaitOrRun({int? timestamp}) =>
      _impl._waitOrRun(timestamp: timestamp);
}
