import 'package:tekartik_app_date/calendar_time.dart';
import 'package:test/test.dart';

void main() {
  group('time', () {
    test('time', () {
      var time = CalendarTime(seconds: 123456);
      expect(time.toString(), '10:17');

      time = CalendarTime(text: '10:00');
      expect(time.toString(), '10:00');
      time = CalendarTime(text: '1000');
      expect(time.toString(), '10:00');
      time = CalendarTime(text: '10');
      expect(time.toString(), '10:00');
      time = CalendarTime(text: '24:00');
      expect(time.toString(), '00:00');
    });
  });
}
