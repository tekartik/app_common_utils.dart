import 'package:tekartik_app_rx/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('helpers', () {
    test('toBehaviorSubject', () async {
      var subject = Stream.fromIterable([1, 2, 3]).toBehaviorSubject();
      expect(await subject.first, 1);
      expect(subject.value, 1);
    });
  });
}
