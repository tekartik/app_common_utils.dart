import 'package:tekartik_app_common_utils/common_utils_import.dart';
import 'package:tekartik_app_common_utils/lazy_runner.dart';
import 'package:test/test.dart';

const kTestTimeout = Duration(milliseconds: 10);
void main() {
  // debugLazyRunner = devTrue;
  group('Lazy runner', () {
    test('waitTriggered', () async {
      var completer = Completer<void>();
      var runner = LazyRunner(
        action: (count) async {
          await completer.future;
        },
      );
      runner.trigger();
      await expectLater(
        runner.waitTriggered().timeout(kTestTimeout),
        throwsA(isA<TimeoutException>()),
      );
      completer.complete();
      await runner.waitTriggered();
    });
    test('close', () async {
      var completer = Completer<void>();
      var actionStarted = Completer<void>();
      var runner = LazyRunner(
        action: (count) async {
          actionStarted.complete();
          await completer.future;
        },
      );
      runner.trigger();
      await actionStarted.future;
      await expectLater(
        runner.close().timeout(kTestTimeout),
        throwsA(isA<TimeoutException>()),
      );
      completer.complete();
      await runner.close();
    });
    // debugLazyRunner = true;
    test('once', () async {
      var i = 0;
      var runner = LazyRunner(
        action: (count) async {
          await sleep(20);
          return ++i;
        },
      );
      expect((await runner.triggerAndWait()), 1);
      expect((await runner.waitCurrent()), 1);
      expect((await runner.waitTriggered()), 1);
      expect((runner.lastResult), 1);
      expect(i, 1);
    });
    test('periodic', () async {
      var runner = LazyRunner.periodic(
        duration: const Duration(milliseconds: 10),
        action: (count) async {},
      );
      await sleep(150);
      await runner.close();

      /// 6 on windows
      /// print('count: ${runner.count}');
      expect(runner.count, lessThan(17));
      expect(runner.count, greaterThan(2));
    });
    test('trigger', () async {
      var runner = LazyRunner(
        action: (count) async {
          await sleep(20);
        },
      );
      for (var i = 0; i < 10; i++) {
        await sleep(5);
        runner.trigger();
      }
      runner.dispose();
      expect(runner.count, lessThan(7));
      expect(runner.count, greaterThan(2));
    });

    test('triggerAndWait', () async {
      var i = 0;
      var runner = LazyRunner(
        action: (count) async {
          await sleep(10);
          i++;
        },
      );
      await runner.triggerAndWait();
      expect(i, 1);
      await runner.triggerAndWait();
      expect(i, 2);
    });

    test('throws', () async {
      var runner = LazyRunner(
        action: (count) async {
          throw StateError('error');
        },
      );
      expect(await runner.waitCurrent(), null);

      await expectLater(
        () => runner.triggerAndWait(),
        throwsA(isA<StateError>()),
      );
      runner.dispose();
    });
  });
}
