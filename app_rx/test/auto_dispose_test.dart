import 'package:tekartik_app_rx/auto_dispose.dart';
import 'package:test/test.dart';

/// Test mixin
class _AutoDisposer with AutoDisposeMixin {}

void main() {
  group('audi', () {
    test('subject', () async {
      var disposer = _AutoDisposer();
      var subject = BehaviorSubject<void>();
      disposer.audiAddStreamController(subject);
      expect(subject.isClosed, isFalse);
      disposer.audiDispose(subject);
      expect(subject.isClosed, isTrue);
    });
  });
}
