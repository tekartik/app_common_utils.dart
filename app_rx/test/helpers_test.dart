// ignore_for_file: deprecated_member_use_from_same_package

import 'package:tekartik_app_rx/helpers.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

void main() {
  group('helpers', () {
    test('toBehaviorSubject', () async {
      var subject = Stream.fromIterable([1, 2, 3]).toBehaviorSubject();

      var completer = Completer<void>();
      subject.first.then((value) {
        expect(value, 1);
        expect(subject.value, 1);
      }).unawait();

      StreamSubscription? subscription1;
      subscription1 = subject.listen((data) {
        if (data == 1) {
          subscription1?.cancel();
          subscription1 = null;
        }
      });
      subject.listen((data) {
        if (data == 3) {
          completer.complete();
        }
      });
      await completer.future;
      expect(subscription1, isNull);
      expect(await subject.first, 3);
      expect(subject.value, 3);
      await subject.close();
    });
    test('toBroadcastValueStream', () async {
      var subject = Stream.fromIterable([1, 2, 3]).toBroadcastValueStream();

      var completer = Completer<void>();
      subject.first.then((value) {
        expect(value, 1);
        expect(subject.value, 1);
      }).unawait();

      StreamSubscription? subscription1;
      subscription1 = subject.listen((data) {
        if (data == 1) {
          subscription1?.cancel();
          subscription1 = null;
        }
      });
      subject.listen((data) {
        if (data == 3) {
          completer.complete();
        }
      });
      await completer.future;
      expect(subscription1, isNull);
      expect(await subject.first, 3);
      expect(subject.value, 3);
      await subject.close();
    });
    test('toBroadcastStream', () async {
      var subject = Stream.fromIterable([1, 2, 3]).toBroadcastStream();

      var completer = Completer<void>();
      subject.first.then((value) {
        expect(value, 1);
      }).unawait();

      StreamSubscription? subscription1;
      subscription1 = subject.listen((data) {
        if (data == 1) {
          subscription1?.cancel();
          subscription1 = null;
        }
      });
      subject.listen((data) {
        if (data == 3) {
          completer.complete();
        }
      });
      await completer.future;
      expect(subscription1, isNull);

      await subject.close();
    });
    test('cancel toBehaviorSubject', () async {
      var streamController = StreamController<int>(sync: true);
      var subject = streamController.stream.toBehaviorSubject();

      streamController.add(1);
      expect(await subject.first, 1);
      await sleep(1);

      try {
        // expect(await subject.first, 1);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }

      await subject.close();
    });
    test('cancel toBroadcastValueStream', () async {
      var streamController = StreamController<int>(sync: true);
      var subject = streamController.stream.toBroadcastValueStream();

      streamController.add(1);
      await subject.first;
      await sleep(1);
      await subject.first;

      await subject.close();
    });
    test('api', () {
      // ignore: unnecessary_statements
      BroadcastValueStream;
    });
    test('broadcast streams are broadcast', () async {
      var stream = Stream.fromIterable([1]).toBroadcastStream();
      var valueStream = Stream.fromIterable([1]).toBroadcastValueStream();
      expect(stream.isBroadcast, isTrue);
      expect(valueStream.isBroadcast, isTrue);
      await stream.close();
      await valueStream.close();
    });
    for (var valueStream in [false, true]) {
      test('forward error and done (value stream: $valueStream)', () async {
        var source = StreamController<int>();
        late Stream<int> stream;
        late Future<void> Function() close;
        if (valueStream) {
          var broadcast = source.stream.toBroadcastValueStream();
          stream = broadcast;
          close = broadcast.close;
        } else {
          var broadcast = source.stream.toBroadcastStream();
          stream = broadcast;
          close = broadcast.close;
        }
        var values = <int>[];
        var errors = <Object>[];
        var done = Completer<void>();
        stream.listen(
          values.add,
          onError: errors.add,
          onDone: () => done.complete(),
        );
        source.add(1);
        source.addError(StateError('boom'));
        await source.close();
        await done.future;
        expect(values, [1]);
        expect(errors, [isA<StateError>()]);
        if (stream is BroadcastValueStream<int>) {
          expect(stream.hasError, isTrue);
        }
        await close();
      });
    }
    test('value stream late listener after source done', () async {
      var stream = Stream.fromIterable([1, 2]).toBroadcastValueStream();
      expect(await stream.toList(), [1, 2]);
      expect(stream.value, 2);
      await stream.close();
    });
  });
}
