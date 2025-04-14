import 'package:tekartik_app_common_utils/common_utils_import.dart';
import 'package:tekartik_app_common_utils/lazy_runner.dart';
import 'package:tekartik_app_common_utils/src/lazy_runner/lazy_runner.dart'
    show LazyRunnerPrvExtension;
import 'package:test/test.dart';

const kTestTimeout = Duration(milliseconds: 10);
void main() {
  // debugLazyRunner = devTrue;
  group('Lazy runner', () {
    test('never', () async {
      var runner = LazyRunner(
        action: (count) async {
          throw StateError('never');
        },
      );
      expect(runner.count, 0);
      expect(runner.lastResult, null);
      expect(runner.isRunning, false);
      expect(runner.isTriggered, false);
      expect(runner.disposed, false);
      expect(await runner.waitCurrent(), isNull);
      expect(await runner.waitTriggered(), isNull);
      await runner.close();
      expect(runner.count, 0);
      expect(runner.lastResult, null);
      expect(runner.isRunning, false);
      expect(runner.isTriggered, false);
      expect(runner.disposed, isTrue);
      expect(await runner.waitCurrent(), isNull);
      expect(await runner.waitTriggered(), isNull);
    });
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
    test('waitCurrent', () async {
      var completer = Completer<void>();
      var runner = LazyRunner(
        action: (index) async {
          await completer.future;
          return index + 1;
        },
      );
      runner.trigger();
      expect(await runner.waitCurrent(), isNull);

      completer.complete();
      expect(await runner.waitCurrent(), 1);
    });
    test('close', () async {
      var completer = Completer<int>();
      var actionStarted = Completer<void>();
      var runner = LazyRunner(
        action: (count) async {
          actionStarted.complete();
          return await completer.future;
        },
      );
      runner.trigger();
      await actionStarted.future;
      await expectLater(
        runner.close().timeout(kTestTimeout),
        throwsA(isA<TimeoutException>()),
      );
      completer.complete(1);
      await runner.close();
      expect(await runner.waitCurrent(), 1);
      expect(await runner.waitTriggered(), 1);
    });
    test('dispose', () async {
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
      runner.dispose();
      expect(await runner.waitCurrent(), isNull);
      expect(await runner.waitTriggered(), isNull);
    });
    // debugLazyRunner = true;
    test('once', () async {
      var i = 0;
      late LazyRunner runner;
      runner = LazyRunner(
        action: (index) async {
          expect(index, 0);
          expect(runner.count, 1);
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
      late int lastIndex;
      var runner = LazyRunner.periodic(
        duration: const Duration(milliseconds: 10),
        action: (index) async {
          lastIndex = index;
        },
      );
      await sleep(150);
      await runner.close();

      /// 6 on windows
      /// print('count: ${runner.count}');
      expect(runner.count, lessThan(17));
      expect(runner.count, greaterThan(2));
      expect(lastIndex, runner.count - 1);
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
          return ++i;
        },
      );
      expect(await runner.triggerAndWait(), 1);
      expect(i, 1);
      expect(await runner.triggerAndWait(), 2);
      expect(i, 2);
      runner.dispose();
      expect(await runner.waitCurrent(), 2);
      expect(await runner.waitTriggered(), 2);
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
