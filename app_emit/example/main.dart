// ignore_for_file: avoid_print

import 'dart:async';

import 'package:tekartik_app_emit/emit.dart';

/// Loads a name once; once loaded, it is returned without a Future.
class NameCache {
  final _controllers = <int, EmitFutureOrController<String>>{};

  EmitFutureOr<String> get(int id) {
    var controller = _controllers[id];
    if (controller == null) {
      controller = _controllers[id] = EmitFutureOrController<String>();
      _fetch(id, controller);
    }
    return controller.futureOr;
  }

  Future<void> _fetch(int id, EmitFutureOrController<String> controller) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!controller.isCompleted) {
      controller.complete('name_$id');
    }
  }

  /// Cancels the pending loads.
  void close() {
    for (var controller in _controllers.values) {
      controller.close();
    }
  }
}

Future<void> main() async {
  var cache = NameCache();

  // Pending: toFutureOr() is a Future.
  var name = cache.get(1).toFutureOr();
  print(name is Future); // true
  print(await name); // name_1

  // Loaded: the value itself, at once (a widget can build without waiting).
  print(cache.get(1).toFutureOr()); // name_1
  cache.get(1).listen((name) => print('listen: $name')); // listen: name_1

  // A pending load cancelled: the listeners get an EmitCancelException.
  var pending = cache.get(2);
  pending.listen(
    (name) => print('never'),
    onError: (Object error) => print('error: $error'),
  );
  cache.close(); // error: Emit cancelled due to: closed

  // An immediate value, null allowed for a nullable type.
  print(EmitFutureOr<int?>.withValue(null).toFutureOr()); // null
}
