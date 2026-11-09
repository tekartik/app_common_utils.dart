import 'package:tekartik_app_csv/app_csv.dart';
import 'package:test/test.dart';

/// Regression tests of the 2026-11-09 review.
void main() {
  test('csvToMapList row shorter than the header', () {
    expect(csvToMapList('a,b,c\r\n1\r\n4,5\r\n'), [
      {'a': '1', 'b': null, 'c': null},
      {'a': '4', 'b': '5', 'c': null},
    ]);
  });
  test('mapListToCsv non string keys', () {
    expect(
      mapListToCsv([
        {1: 'a', 'b': 2},
        {1: 'c'},
      ]),
      '1,b\r\na,2\r\nc,',
    );
  });
}
