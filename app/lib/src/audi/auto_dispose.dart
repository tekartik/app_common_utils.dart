import 'dart:async';

import 'package:tekartik_app_common_utils/auto_dispose.dart';

/// Auto dispose function
typedef AutoDisposeFunction = void Function();

/// Auto dispose self function
typedef AutoDisposeSelfFunction<T extends Object> = void Function(T object);

/// Auto dispose class
class _AutoDisposer<T extends Object> {
  /// Dispose function
  final AutoDisposeFunction dispose;

  /// Object to dispose
  T object;

  /// Constructor
  _AutoDisposer({required this.object, required this.dispose});
}

/// Auto dispose extension
extension AutoDisposeDisposableExt on AutoDispose {
  /// Dispose the object
  T audiAddDisposable<T extends AutoDisposable>(T disposable) {
    return audiAdd(disposable, disposable.audiDispose);
  }
}

/// Auto dispose interface
abstract class AutoDispose {
  /// Add a StreamSubscription to the auto dispose list
  StreamSubscription<T> audiAddStreamSubscription<T>(
    StreamSubscription<T> subscription,
  );

  /// Add a StreamController to the auto dispose list
  StreamController<T> audiAddStreamController<T>(
    StreamController<T> controller,
  );

  /// Add a disposer to the auto dispose list, if object is null.
  T audiAdd<T extends Object>(T object, AutoDisposeFunction dispose);

  /// Add a disposer to the auto dispose list, if object is null.
  T audiAddSelf<T extends Object>(T object, AutoDisposeSelfFunction dispose);

  /// Add a function to the auto dispose list, audiDisposeAll will dispose it
  void audiAddFunction(AutoDisposeFunction dispose);

  /// Dispose an object
  void audiDispose<T extends Object>(T? object);

  /// Dispose a function
  void audiDisposeFunction(AutoDisposeFunction dispose);

  /// Dispose all disposers
  void audiDisposeAll();
}

/// Auto dispose mixin
mixin AutoDisposeMixin implements AutoDispose {
  final _disposers = <Object, _AutoDisposer>{};

  /// No associated object
  final _disposeFunctions = <AutoDisposeFunction>[];

  @override
  StreamSubscription<T> audiAddStreamSubscription<T>(
    StreamSubscription<T> subscription,
  ) {
    return audiAdd(subscription, subscription.cancel);
  }

  @override
  StreamController<T> audiAddStreamController<T>(
    StreamController<T> controller,
  ) {
    return audiAdd(controller, controller.close);
  }

  /// Add a disposer to the auto dispose list
  T _audiAdd<T extends Object>(_AutoDisposer<T> disposer) {
    _disposers[disposer.object] = disposer;
    return disposer.object;
  }

  @override
  T audiAdd<T extends Object>(T object, AutoDisposeFunction dispose) {
    return _audiAdd<T>(_AutoDisposer(object: object, dispose: dispose));
  }

  @override
  T audiAddSelf<T extends Object>(
    T object,
    AutoDisposeSelfFunction<T> dispose,
  ) {
    return _audiAdd<T>(
      _AutoDisposer(object: object, dispose: () => dispose(object)),
    );
  }

  @override
  void audiDispose<T extends Object>(T? object) {
    if (object == null) {
      return;
    }
    var disposer = _disposers.remove(object);
    disposer?.dispose();
  }

  @override
  void audiAddFunction(AutoDisposeFunction dispose) {
    _disposeFunctions.add(dispose);
  }

  @override
  void audiDisposeFunction(AutoDisposeFunction function) {
    if (_disposeFunctions.remove(function)) {
      function();
    }
  }

  /// Call this method in dispose method of the widget
  @override
  void audiDisposeAll() {
    for (var function in _disposeFunctions) {
      function();
    }
    _disposeFunctions.clear();
    for (var entry in _disposers.values) {
      entry.dispose();
    }
    _disposers.clear();
  }
}

/// Private extension
extension AutoDisposeMixinPrvExtension on AutoDisposeMixin {
  /// Get the count of disposers
  int get length => _disposeFunctions.length + _disposers.length;
}
