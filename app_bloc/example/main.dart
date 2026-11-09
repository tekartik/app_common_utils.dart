// ignore_for_file: avoid_print

import 'dart:async';

import 'package:tekartik_app_bloc/base_bloc.dart';

/// A counter: the state as a stream plus its last value.
class CounterBloc extends BaseBloc {
  final _controller = StreamController<int>.broadcast();
  var _count = 0;

  Stream<int> get counts => _controller.stream;
  int get count => _count;

  Future<void> incrementLater() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // The screen may be gone during the await.
    if (disposed) {
      return;
    }
    _controller.add(++_count);
  }

  @override
  void dispose() {
    // Own resources first, then super.dispose().
    unawaited(_controller.close());
    super.dispose();
  }
}

Future<void> main() async {
  var bloc = CounterBloc();
  bloc.counts.listen((count) => print('count: $count'));
  await bloc.incrementLater(); // count: 1
  var pending = bloc.incrementLater();
  bloc.dispose();
  await pending; // nothing added to the closed controller
  print('disposed: ${bloc.disposed}, count: ${bloc.count}');
  // disposed: true, count: 1
}
