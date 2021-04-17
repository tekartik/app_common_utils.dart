import 'package:tekartik_app_cv/src/column.dart';
import 'package:test/test.dart';

void main() {
  group('Column', () {
    test('equals', () async {
      expect(CvColumn('name'), CvColumn('name'));
      expect(CvColumn('name'), isNot(CvColumn('name2')));
    });
  });
}
