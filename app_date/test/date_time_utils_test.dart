import 'package:tekartik_app_date/date_time_utils.dart';
import 'package:test/test.dart';

void main() {
  test('sanitizeToSeconds', () {
    var date = DateTime(2023, 10, 1, 12, 30, 45, 16, 28);
    expect(date.sanitizeToSeconds(), '20231001T123045');
  });
}
