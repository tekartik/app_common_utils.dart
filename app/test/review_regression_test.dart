import 'dart:typed_data';

import 'package:tekartik_app_common_utils/asset/asset_bundle.dart';
import 'package:tekartik_app_common_utils/common_utils_import.dart';
import 'package:tekartik_app_common_utils/lazy_runner.dart';
import 'package:tekartik_app_common_utils/single_flight.dart';
import 'package:test/test.dart';

/// Regression tests of the 2026-11-09 review.
void main() {
  group('LazyRunner', () {
    test('triggerAndWait after close fails instead of hanging', () async {
      var runner = LazyRunner<int>(action: (index) async => index);
      expect(await runner.triggerAndWait(), 0);
      await runner.close();
      await expectLater(
        runner.triggerAndWait().timeout(const Duration(seconds: 5)),
        throwsA(isA<StateError>()),
      );
    });
    test('triggerAndWait pending when closed during the action', () async {
      var actionStarted = Completer<void>();
      var actionEnd = Completer<void>();
      var runner = LazyRunner<int>(
        action: (index) async {
          if (!actionStarted.isCompleted) {
            actionStarted.complete();
          }
          await actionEnd.future;
          return index;
        },
      );
      var first = runner.triggerAndWait();
      await actionStarted.future;
      // Queued behind the running action, never run since closed.
      var second = runner.triggerAndWait();
      var closeFuture = runner.close();
      actionEnd.complete();
      expect(await first, 0);
      await closeFuture;
      await expectLater(
        second.timeout(const Duration(seconds: 5)),
        throwsA(isA<StateError>()),
      );
      expect(runner.count, 1);
    });
    test('triggerAndWait pending when disposed during the action', () async {
      var actionStarted = Completer<void>();
      var actionEnd = Completer<void>();
      var runner = LazyRunner<int>(
        action: (index) async {
          if (!actionStarted.isCompleted) {
            actionStarted.complete();
          }
          await actionEnd.future;
          return index;
        },
      );
      var first = runner.triggerAndWait();
      await actionStarted.future;
      var second = runner.triggerAndWait();
      runner.dispose();
      actionEnd.complete();
      expect(await first, 0);
      await expectLater(
        second.timeout(const Duration(seconds: 5)),
        throwsA(isA<StateError>()),
      );
    });
  });
  test('SingleFlight.waitOrRun concurrent first calls share one run', () async {
    var calls = 0;
    var flight = SingleFlight<int>(() async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return calls;
    });
    var results = await Future.wait([
      flight.waitOrRun(),
      flight.waitOrRun(),
      flight.waitOrRun(),
    ]);
    expect(results, [1, 1, 1]);
    expect(calls, 1);
    // Cached afterwards.
    expect(await flight.waitOrRun(), 1);
    expect(calls, 1);
    await flight.close();
  });
  test('TkAssetBundleMemory.loadByteData of a view', () async {
    var bundle = TkAssetBundleMemory();
    var all = Uint8List.fromList([1, 2, 3, 4]);
    bundle.setBytes('view', Uint8List.sublistView(all, 2));
    var byteData = await bundle.loadByteData('view');
    expect(byteData.lengthInBytes, 2);
    expect(byteData.getUint8(0), 3);
    expect(byteData.getUint8(1), 4);
  });
}
