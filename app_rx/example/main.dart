// ignore_for_file: avoid_print

import 'dart:async';

import 'package:tekartik_app_rx/auto_dispose.dart';
import 'package:tekartik_app_rx/helpers.dart';

/// A tiny view model: a counter shared with several widgets.
class CounterModel with AutoDisposeMixin {
  final _counter = BehaviorSubject<int>.seeded(0);
  final _events = StreamController<String>();

  /// Current count, replayed to every new listener.
  late final ValueStream<int> count = _counter.stream;

  /// One shot events, not replayed.
  late final BroadcastStream<String> events = _events.stream
      .toBroadcastStream();

  /// Derived value, computed only once someone listens.
  late final BroadcastValueStream<String> label = audiAddBroadcastValueStream(
    _counter.map((value) => 'count: $value').toBroadcastValueStream(),
  );

  CounterModel() {
    audiAddBehaviorSubject(_counter);
    audiAdd(events, events.close);
    audiAddStreamController(_events);
  }

  void increment() {
    _counter.add(_counter.value + 1);
    if (_counter.value == 2) {
      _events.add('reached 2');
    }
  }

  /// Closes everything registered.
  void dispose() => audiDisposeAll();
}

Future<void> main() async {
  var model = CounterModel();
  var subscriptions = [
    model.label.listen((label) => print(label)),
    model.events.listen((event) => print('event: $event')),
  ];
  model.increment();
  model.increment();
  await Future<void>.delayed(Duration.zero);

  // A late listener gets the last label at once.
  print('late: ${await model.label.first}'); // late: count: 2
  print(model.label.lastEventOrNull?.isData); // true

  for (var subscription in subscriptions) {
    await subscription.cancel();
  }
  model.dispose();
}
