import 'dart:async';

import 'package:tekartik_app_emit/emit.dart';
import 'package:test/test.dart';

/// Runs [body] and returns the errors it leaves uncaught.
Future<List<Object>> _uncaughtErrors(void Function() body) async {
  var errors = <Object>[];
  var done = Completer<void>();
  runZonedGuarded(() {
    body();
    Future<void>.delayed(const Duration(milliseconds: 10)).then((_) {
      done.complete();
    });
  }, (error, stackTrace) => errors.add(error));
  await done.future;
  return errors;
}

/// Regression tests of the 2026-11-09 review.
void main() {
  test('withValue(null) completes with null', () async {
    var futureOr = EmitFutureOr<int?>.withValue(null);
    expect(futureOr.toFutureOr(), isNull);
    expect(
      await futureOr.toFuture().timeout(const Duration(seconds: 5)),
      isNull,
    );
  });
  test('a null value can be read', () async {
    var controller = EmitFutureOrController<int?>(nullValue: true);
    expect(controller.futureOr.toFutureOr(), isNull);
    var values = <int?>[];
    controller.futureOr.listen(values.add);
    expect(values, [null]);

    controller = EmitFutureOrController<int?>();
    controller.complete(null);
    expect(controller.futureOr.toFutureOr(), isNull);
  });
  test('close without listener leaves no uncaught error', () async {
    expect(
      await _uncaughtErrors(() {
        EmitFutureOrController<int>().close();
      }),
      isEmpty,
    );
    expect(
      await _uncaughtErrors(() {
        EmitFutureOrController<int>().cancel(reason: 'test');
      }),
      isEmpty,
    );
  });
  test('cancel a subscription without onError', () async {
    expect(
      await _uncaughtErrors(() {
        var controller = EmitFutureOrController<int>();
        controller.futureOr.listen((_) {}).cancel();
      }),
      isEmpty,
    );
  });
  test('the cancel error is still given to a later listener', () async {
    var controller = EmitFutureOrController<int>()..cancel();
    await expectLater(
      controller.futureOr.toFuture(),
      throwsA(isA<EmitCancelException>()),
    );
  });
  test('an error remains uncaught without onError', () async {
    var errors = await _uncaughtErrors(() {
      var controller = EmitFutureOrController<int>();
      controller.futureOr.listen((_) {});
      controller.completeError(StateError('boom'));
    });
    expect(errors, [isA<StateError>()]);
  });
}
