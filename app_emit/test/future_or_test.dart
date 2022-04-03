import 'dart:async';

import 'package:tekartik_app_emit/emit.dart';
import 'package:test/test.dart';

class TestException implements Exception {}

void main() {
  group('future_or', () {
    group('stream', () {
      test('sync', () {
        var controller = StreamController<int>(sync: true);
        controller.add(1);

        int? got;
        var subscription = controller.stream.listen((data) {
          got = data;
        });

        controller.close();
        expect(got, isNull);
        subscription.cancel();
      });

      test('emit', () {
        var controller = EmitFutureOrController<int>();
        controller.complete(1);

        int? got;
        var futureOr = controller.futureOr;
        var subscription = futureOr.listen((data) {
          got = data;
        });
        controller.close();

        expect(got, 1);
        subscription.cancel();
      });

      test('null_listener', () {
        final emitFutureOr = EmitFutureOr<int>.withValue(1);
        var subscription = emitFutureOr.listen(null);
        expect(subscription.asFutureOr(), 1);
      });
    });
    group('controller', () {
      test('direct_cancel', () async {
        var controller = EmitFutureOrController();
        // This is needed to prevent a crash in unit test
        var subscription =
            controller.futureOr.listen((_) => null, onError: (e) {
          expect(e, const TypeMatcher<EmitCancelException>());
        });
        controller.cancel();

        try {
          await subscription.asFutureOr();
        } on EmitCancelException catch (_) {}
      });

      test('value', () async {
        var completer = EmitFutureOrController(value: 1);
        expect(await completer.futureOr.toFuture(), 1);
        expect(completer.isCancelled, isFalse);
        completer.cancel();
        expect(completer.isCancelled, isTrue);

        // Ok to cancel again
        completer.cancel();
        expect(completer.isCancelled, isTrue);

        try {
          completer.complete();
          fail('should fail');
        } on StateError catch (_) {}
      });

      test('complete', () async {
        var completer = EmitFutureOrController();

        expect(completer.isCancelled, isFalse);
        expect(completer.isCompleted, isFalse);
        var completed = false;
        unawaited(completer.futureOr.toFuture().then((_) {
          completed = true;
        }));
        completer.complete(1);
        // Main difference between sync and async here
        expect(completed, isTrue);
        expect(completer.isCancelled, isFalse);
        expect(completer.isCompleted, isTrue);
        expect(await completer.futureOr.toFuture(), 1);
        // Ok to cancel
        completer.cancel();
        expect(completer.isCancelled, isTrue);

        try {
          completer.complete();
          fail('should fail');
        } on StateError catch (_) {}
      });

      test('complete_error', () async {
        var controller = EmitFutureOrController();

        expect(controller.isCancelled, isFalse);
        expect(controller.isCompleted, isFalse);
        var completed = false;
        unawaited(controller.futureOr.toFuture().catchError((e) {
          expect(e, const TypeMatcher<TestException>());
          completed = true;
        }));
        controller.completeError(TestException());
        // Main difference between sync and async here
        expect(completed, isTrue);
        expect(controller.isCancelled, isFalse);
        expect(controller.isCompleted, isTrue);

        try {
          await controller.futureOr.toFuture();
          fail('should fail');
        } on TestException catch (_) {}
        // Ok to cancel
        controller.cancel();
        expect(controller.isCancelled, isTrue);

        try {
          controller.complete();
          fail('should fail');
        } on StateError catch (_) {}
      });
      test('cancel', () async {
        var controller = EmitFutureOrController();
        expect(controller.isCancelled, isFalse);
        expect(controller.isCompleted, isFalse);
        var cancelled = false;
        unawaited(controller.futureOr.toFuture().catchError((e) {
          expect(e, const TypeMatcher<EmitCancelException>());
          cancelled = true;
        }));
        controller.cancel();
        // Main difference between sync and async here
        expect(cancelled, isTrue);
        expect(controller.isCancelled, isTrue);
        expect(controller.isCompleted, isTrue);

        try {
          expect(await controller.futureOr.toFuture(), isNull);
          fail('should fail');
        } on EmitCancelException catch (_) {}

        // Ok to cancel again
        controller.cancel();
        expect(controller.isCancelled, isTrue);

        try {
          controller.complete();
          fail('should fail');
        } on StateError catch (_) {}
      });
    });
  });
}
