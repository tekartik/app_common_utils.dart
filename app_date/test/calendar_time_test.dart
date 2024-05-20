import 'package:tekartik_app_date/calendar_time.dart';
import 'package:tekartik_app_date/time_offset.dart';
import 'package:test/test.dart';

void main() {
  group('time', () {
    test('text', () {
      var time = CalendarTime(seconds: 123456);
      expect(time.text, '34:17:36');
      expect(time.toString(), 'Time(34:17:36)');
      expect(time.hours, 34);
      expect(time.fullHours, 34);
      expect(time.hourMinutes, 17);
      expect(time.minuteSeconds, 36);
      time = CalendarTime(text: '10:00');
      expect(time.text, '10:00');
      time = CalendarTime(text: '1000');
      expect(time.text, '10:00');
      time = CalendarTime(text: '10');
      expect(time.text, '10:00');
      time = CalendarTime(text: '24:00');
      expect(time.text, '24:00');
      time = CalendarTime(text: '25:00');
      expect(time.text, '25:00');
      time = CalendarTime(text: '1:01:12');
      expect(time.text, '01:01:12');
      expect(time.hours, 1);
      expect(time.minutes, 61);
      expect(time.seconds, 3672);
      expect(time.fullHours, 1);
      expect(time.hourMinutes, 1);
      expect(time.hours, 1);
      expect(time.minuteSeconds, 12);
      time = CalendarTime(text: '1:01');
      expect(time.text, '01:01');
      expect(time.hours, 1);
      expect(time.minutes, 61);
      expect(time.seconds, 3660);

      expect(time.fullHours, 1);
      expect(time.hourMinutes, 1);
      expect(time.hours, 1);
      expect(time.minuteSeconds, 0);
      time = CalendarTime(text: '-1:01:12');
      expect(time.text, '-01:01:12');
      expect(time.hours, -1);
      expect(time.minutes, -61);
      expect(time.seconds, -3672);
      expect(time.fullHours, -2);
      expect(time.hourMinutes, 58);
      expect(time.hours, -1);
      expect(time.minuteSeconds, 48);
      time = CalendarTime(text: '-1:01');
      expect(time.text, '-01:01');
      expect(time.hours, -1);
      expect(time.minutes, -61);
      expect(time.seconds, -3660);

      expect(time.fullHours, -2);
      expect(time.hourMinutes, 59);
      expect(time.hours, -1);
      expect(time.minuteSeconds, 0);

      expect(CalendarTime.zero().text, '00:00');
    });
    test('fromSeconds', () {
      expect(CalendarTime.fromSeconds(123456).text, '34:17:36');
    });
    test('fromText', () {
      expect(CalendarTime.fromText('34:17:36').seconds, 123456);
    });
    test('dateTime', () {
      var dateTime = DateTime.utc(2024, 5, 7, 15, 5, 13);
      var time = CalendarTime.fromDateTime(dateTime);
      expect(time.text, '15:05:13');
    });
    test('addOffset', () {
      var time = CalendarTime.fromText('10:00');
      expect(time.addOffset(TimeOffset(1, 2)).text, '11:02');
      expect(time.addOffset(TimeOffset(-1, -2)).text, '08:58');
    });
  });
}
