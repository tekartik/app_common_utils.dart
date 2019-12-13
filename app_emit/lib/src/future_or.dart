import 'dart:async';

import 'package:tekartik_app_emit/src/exception.dart';
import 'package:tekartik_common_utils/model/model.dart';

class EmitFutureOrSubscription<T> {
  final EmitFutureOr<T> _emitFutureOr;

  EmitFutureOrController<T> get _controller => _emitFutureOr._controller;

  EmitFutureOrSubscription._(this._emitFutureOr);

  void cancel({String reason}) {
    _controller.cancel(reason: reason);
  }

  FutureOr<T> asFutureOr() => _controller._futureOr;
}

/// Emit to listen to
class EmitFutureOr<T> {
  final EmitFutureOrController<T> _controller;

  /// Helper to create an immediate value
  factory EmitFutureOr.withValue(T value) {
    return EmitFutureOrController(value: value, nullValue: value == true)
        .futureOr;
  }

  EmitFutureOr._(this._controller);

  EmitFutureOrSubscription<T> listen(dynamic Function(T value) onValue,
      {Function onError}) {
    final subscription = EmitFutureOrSubscription._(this);

    // if completed send right await
    if (_controller._hasValue) {
      if (onValue != null) {
        onValue(_controller._value);
      }
    } else {
      var future = _controller._completer.future.then((value) {
        if (onValue != null) {
          onValue(value);
        }
      });
      if (onError != null) {
        future.catchError((error, StackTrace stackTrace) {
          // try with and without a stack trace
          try {
            onError(error, stackTrace);
          } catch (_) {
            onError(error);
          }
        });
      }
    }
    return subscription;
  }

  /// Return the actual value
  FutureOr<T> toFutureOr() => _controller._futureOr;

  /// Return the future
  Future<T> toFuture() => _controller._completer.future;
}

/// A completer that can be cancelled and with value that could be accessed
/// immediately.
///
/// It supports a single listener
class EmitFutureOrController<T> {
  final Completer<T> _completer = Completer<T>.sync();

  /// Only completed immediately if [value] is not null or [nullValue] is true,
  /// [value] taking precedence over [nullValue]
  EmitFutureOrController({T value, bool nullValue}) {
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
  T _value;
  bool _isCancelled = false;

  FutureOr<T> get _futureOr {
    if (_hasValue) {
      return _value;
    } else {
      return _completer.future;
    }
  }

  /// Completes with the supplied values.
  void complete([T value]) {
    _value = value;
    _completer.complete(value);
  }

  /// Safe to cancel any time.
  void cancel({String reason}) {
    if (!_isCancelled) {
      _isCancelled = true;
      if (!isCompleted) {
        completeError(EmitCancelException(reason));
      }
    }
  }

  /// true when completed of cancelled
  bool get isCompleted => _completer.isCompleted;

  /// true when cancelled
  bool get isCancelled => _isCancelled;

  // Complete [with an error.
  void completeError(Object error, [StackTrace stackTrace]) {
    _error = error ??= Exception('error');
    _completer.completeError(error, stackTrace);
  }

  Model toDebugModel() {
    var model = Model();
    model['completer'] = identityHashCode(_completer);
    model.setValue('error', _error);
    model.setValue('completed', isCompleted);
    model.setValue('value', isCompleted ? _value : null,
        presentIfNull: isCompleted);
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
