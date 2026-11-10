// ignore_for_file: avoid_print

import 'package:tekartik_app_rx_bloc/auto_dispose_base_bloc.dart';
import 'package:tekartik_app_rx_bloc/auto_dispose_state_base_bloc.dart';

/// A counter whose state is published as a ValueStream.
class CounterBloc extends AutoDisposeStateBaseBloc<int> {
  /// Registered on first access, closed by dispose().
  late final busy = audiAddBehaviorSubject(BehaviorSubject.seeded(false));

  CounterBloc() {
    // No initial value until the first add.
    add(0);
  }

  void increment() {
    if (disposed) return;
    add(state.value + 1);
  }

  Future<void> incrementLater() async {
    busy.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // The bloc may have been disposed during the await.
    if (disposed) return;
    increment();
    busy.add(false);
  }
}

/// An owner disposing its inner bloc.
class AppBloc extends AutoDisposeBaseBloc {
  late final counter = audiAddDisposable(CounterBloc());
}

Future<void> main() async {
  var app = AppBloc();
  var counter = app.counter;
  var subscription = counter.state.listen((count) => print('count: $count'));
  counter.increment();
  await counter.incrementLater();
  // Listeners are called asynchronously.
  await Future<void>.delayed(Duration.zero);
  print('value: ${counter.state.value}'); // value: 2
  await subscription.cancel();

  app.dispose();
  print('counter disposed: ${counter.disposed}'); // counter disposed: true
  print('busy closed: ${counter.busy.isClosed}'); // busy closed: true
}
