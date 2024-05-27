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

      subject.listen((data) {
        if (data == 3) {
          completer.complete();
        }
      });
      await completer.future;
      expect(await subject.first, 3);
      expect(subject.value, 3);
      await subject.close();
    });
  });
}
