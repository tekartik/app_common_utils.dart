import 'dart:async';

import 'package:cv/cv.dart';
import 'package:tekartik_app_emit/src/exception.dart';

/// The subscription returned by [EmitFutureOr.listen].
class EmitFutureOrSubscription<T> {
  final EmitFutureOr<T> _emitFutureOr;

  EmitFutureOrController<T> get _controller => _emitFutureOr._controller;

  EmitFutureOrSubscription._(this._emitFutureOr);

  /// Cancels the controller itself (for every listener), see
  /// [EmitFutureOrController.cancel].
  void cancel({String? reason}) {
    _controller.cancel(reason: reason);
  }

  /// Same as [EmitFutureOr.toFutureOr].
  FutureOr<T> asFutureOr() => _controller._futureOr;
}

/// The consumer side of an [EmitFutureOrController]: the value itself once
/// available ([toFutureOr]), a future before.
class EmitFutureOr<T> {
  final EmitFutureOrController<T> _controller;

  /// Helper to create an immediate value (null allowed when [T] is
  /// nullable).
  factory EmitFutureOr.withValue(T value) {
    return EmitFutureOrController(
      value: value,
      nullValue: value == null,
    ).futureOr;
  }

  EmitFutureOr._(this._controller);

  /// Calls [onValue] with the value: at once when available, otherwise
  /// when completed.
  ///
  /// [onError] gets `(error, stackTrace)` or `(error)`, also the
  /// [EmitCancelException] of a cancel. Without [onError], a cancel is
  /// ignored and any other error is uncaught.
  EmitFutureOrSubscription<T> listen(
    dynamic Function(T value)? onValue, {
    Function? onError,
  }) {
    final subscription = EmitFutureOrSubscription._(this);

    // if completed send right await
    if (_controller._hasValue) {
      if (onValue != null) {
        // T can be nullable, the value can be null.
        onValue(_controller._value as T);
      }
    } else {
      var future = _controller._completer.future.then((value) {
        if (onValue != null) {
          onValue(value);
        }
      });
      if (onError == null) {
        // A cancel is not an error for a listener without onError (other
        // errors remain uncaught, as for a stream).
        future.catchError(
          (_) {},
          test: (error) => error is EmitCancelException,
        );
      } else {
        future.catchError((Object error, StackTrace stackTrace) {
          // try with and without a stack trace
          try {
            // ignore: avoid_dynamic_calls
            onError(error, stackTrace);
          } catch (_) {
            // ignore: avoid_dynamic_calls
            onError(error);
          }
        });
      }
    }
    return subscription;
  }

  /// The value itself when completed with a value, otherwise the pending
  /// (or failed) future.
  FutureOr<T> toFutureOr() => _controller._futureOr;

  /// The value as a future, in every case.
  Future<T> toFuture() => _controller._completer.future;
}

/// A completer that can be cancelled and with value that could be accessed
/// immediately.
///
/// Synchronous: the listeners run inside [complete], [completeError] and
/// [cancel]. Hand out [futureOr] to the consumers.
class EmitFutureOrController<T> {
  final Completer<T> _completer = Completer<T>.sync();

  /// Only completed immediately if [value] is not null or [nullValue] is true,
  /// [value] taking precedence over [nullValue]
  EmitFutureOrController({T? value, bool? nullValue}) {
    if (value != null) {
      complete(value);
    } else if (nullValue == true) {
      complete(null);
    }
  }

  /// Value direct access if completed, future if pending or cancelled
  EmitFutureOr<T> get futureOr {
    return EmitFutureOr<T>._(this);
  }

  /// True if some value is available
  bool get _hasValue => _completer.isCompleted && _error == null;

  dynamic _error;
  T? _value;
  bool _isCancelled = false;

  FutureOr<T> get _futureOr {
    if (_hasValue) {
      // T can be nullable, the value can be null.
      return _value as T;
    } else {
      return _completer.future;
    }
  }

  /// Completes with the supplied values (a second completion throws a
  /// [StateError]).
  void complete([T? value]) {
    _value = value;
    _completer.complete(value);
  }

  /// Safe to cancel any time.
  void cancel({String? reason}) {
    if (!_isCancelled) {
      _isCancelled = true;
      if (!isCompleted) {
        // Nobody might listen: the cancel error must not be uncaught (a
        // later listener still gets it).
        _completer.future.ignore();
        completeError(EmitCancelException(reason));
      }
    }
  }

  /// true when completed of cancelled
  bool get isCompleted => _completer.isCompleted;

  /// true when cancelled
  bool get isCancelled => _isCancelled;

  // Complete [with an error.
  void completeError(Object error, [StackTrace? stackTrace]) {
    _error = error;
    _completer.completeError(error, stackTrace);
  }

  Model toDebugModel() {
    var model = newModel();
    model['completer'] = identityHashCode(_completer);
    model.setValue('error', _error);
    model.setValue('completed', isCompleted);
    model.setValue(
      'value',
      isCompleted ? _value : null,
      presentIfNull: isCompleted,
    );
    return model;
  }

  @override
  String toString() => 'EmitFutureOrController(${toDebugModel()})';

  /// Cancel if needed
  void close() {
    if (!isCompleted) {
      cancel(reason: 'closed');
    }
  }
}
