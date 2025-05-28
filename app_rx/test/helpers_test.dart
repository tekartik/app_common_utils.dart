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
  });
}
