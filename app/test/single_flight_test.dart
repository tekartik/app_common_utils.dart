import 'dart:async';
import 'package:tekartik_app_common_utils/single_flight.dart';
import 'package:tekartik_app_common_utils/src/single_flight/single_flight.dart'
    show SingleFlightTestExtension;
import 'package:tekartik_common_utils/future_utils.dart';
import 'package:test/test.dart';

void main() {
  group('SingleFlight', () {
    test('run no timestamp', () async {
      var count = 0;
      var singleFlight = SingleFlight<int>(() async {
        count++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return count;
      });
      expect(count, 0);
      var future1 = singleFlight.run();
      expect(count, 1);
      var future2 = singleFlight.run();
      expect(count, 1);
      expect(await future1, 1);
      expect(await future2, 2);
      expect(count, 2);

      // Run again
      var future3 = singleFlight.run();
      expect(await future3, 3);
      expect(count, 3);
    });
    test('run with timestamps', () async {
      var count = 0;
      var singleFlight = SingleFlight<int>(() async {
        count++;
        return count;
      });

      // Initial run (ts 1)
      await singleFlight.testRun(timestamp: 1);
      expect(count, 1);

      // Valid timestamp (1 <= 1)
      expect(await singleFlight.testRun(timestamp: 1), 1);
      expect(count, 1);

      // Expired timestamp (2 > 1) -> new run
      expect(await singleFlight.testRun(timestamp: 2), 2);
      expect(count, 2);

      // Now valid for 2
      expect(await singleFlight.testRun(timestamp: 2), 2);
      expect(count, 2);
    });
    test('coalescing with queue', () async {
      var count = 0;
      var blocking = Completer<void>();
      var singleFlight = SingleFlight<int>(() async {
        count++;
        if (!blocking.isCompleted) {
          await blocking.future;
        }
        return count;
      });

      // Start run 1
      var future1 = singleFlight.run();
      expect(count, 1);

      // Start run 2 (should queue)
      var future2 = singleFlight.run();
      // Start run 3 (should join run 2)
      var future3 = singleFlight.run();

      expect(count, 1); // Still 1

      blocking.complete();
      expect(await future1, 1);

      // Now run 2 starts
      expect(await future2, 2);
      expect(await future3, 2);
      expect(count, 2);
    });

    test('wait', () async {
      var count = 0;
      var singleFlight = SingleFlight<int>(() async {
        count++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return count;
      });

      // Initial state
      expect(await singleFlight.wait(), isNull);
      expect(count, 0);

      // While running
      var future1 = singleFlight.run();
      expect(count, 1);
      expect(await singleFlight.wait(), 1);

      // After run
      await future1;
      expect(await singleFlight.wait(), 1);
    });

    test('waitOrRun with timestamps', () async {
      var count = 0;
      var singleFlight = SingleFlight<int>(() async {
        count++;
        return count;
      });

      // Initial run (ts 1)
      await singleFlight.testWaitOrRun(timestamp: 1);
      expect(count, 1);

      // nope
      expect(await singleFlight.testWaitOrRun(timestamp: 1), 1);
      expect(count, 1);

      // Expired timestamp (2 > 1) -> no new run for waitOrRun, but run does run
      expect(await singleFlight.testWaitOrRun(timestamp: 2), 1);
      expect(await singleFlight.testRun(timestamp: 2), 2);
      expect(count, 2);
    });

    test('auto timestamps', () async {
      var count = 0;
      var singleFlight = SingleFlight<int>(() async {
        count++;
        return count;
      });

      // Run 1 (auto ts 1)
      await singleFlight.run();
      expect(count, 1);

      // waitOrRun with no ts (auto ts 2) -> should re-run because last was 1, now 2
      await singleFlight.waitOrRun();
      expect(count, 1);
    });

    test('error', () async {
      var count = 0;
      var singleFlight = SingleFlight<int>(() async {
        count++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw StateError('error');
      });

      var future1 = singleFlight.run();
      await expectLater(future1, throwsStateError);

      // wait should expose error if running
      var future2 = singleFlight.run();
      // ignore: unawaited_futures
      expectLater(singleFlight.wait(), throwsStateError);
      await expectLater(future2, throwsStateError);

      expect(await singleFlight.wait(), isNull);
      expect(count, 2);
    });
  });

  test('close', () async {
    var count = 0;
    var singleFlight = SingleFlight<int>(() async {
      count++;
      return count;
    });
    var done = false;
    singleFlight.run().then((_) => done = true).unawait();
    expect(done, isFalse);
    await singleFlight.close();
    expect(done, isTrue);
    expect(() => singleFlight.run(), throwsStateError);
  });
}
