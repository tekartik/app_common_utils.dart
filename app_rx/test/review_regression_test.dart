import 'dart:async';

import 'package:tekartik_app_rx/helpers.dart';
import 'package:test/test.dart';

void main() {
  test('BroadcastValueStream.lastEventOrNull is the last event', () async {
    var controller = StreamController<int>(sync: true);
    var stream = controller.stream.toBroadcastValueStream();
    var subscription = stream.listen((_) {}, onError: (Object _) {});
    expect(stream.lastEventOrNull, isNull);

    controller.add(1);
    expect(stream.lastEventOrNull!.isData, isTrue);
    expect(stream.isLastEventValue, isTrue);

    // Same as a BehaviorSubject: an error after a value is the last event
    // (it used to be the previous value).
    var stackTrace = StackTrace.current;
    controller.addError(StateError('boom'), stackTrace);
    var subject = BehaviorSubject<int>.seeded(1)
      ..addError(StateError('boom'), stackTrace);
    expect(subject.lastEventOrNull!.isError, isTrue);
    expect(stream.lastEventOrNull!.isError, isTrue);
    expect(stream.isLastEventError, isTrue);
    expect(
      stream.lastEventOrNull!.errorAndStackTraceOrNull!.stackTrace,
      stackTrace,
    );
    // The value is still there.
    expect(stream.value, 1);

    controller.add(2);
    expect(stream.lastEventOrNull!.requireDataValue, 2);

    await subscription.cancel();
    await subject.close();
    await stream.close();
    await controller.close();
  }, timeout: const Timeout(Duration(seconds: 10)));
}
