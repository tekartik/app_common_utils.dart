import 'package:tekartik_app_date/calendar_day.dart';
import 'package:tekartik_app_date/calendar_time.dart';
import 'package:test/test.dart';

void main() {
  group('day', () {
    test('day', () {
      var day = CalendarDay(text: '2012-01-23');
      expect(day.text, '2012-01-23');
      expect(day.dateTime.toIso8601String(), '2012-01-23T00:00:00.000Z');
      expect(day.localDateTime.toIso8601String(), '2012-01-23T00:00:00.000');

      day = CalendarDay(text: '20120123');
      expect(day.text, '2012-01-23');

      try {
        CalendarDay();
        fail('should fail');
      } on ArgumentError catch (_) {}
    });
    test('fromText invalid', () {
      expect(() => CalendarDay.fromText('not a date'), throwsArgumentError);
      expect(() => CalendarDay(text: 'not a date'), throwsArgumentError);
    });
    test('fromLocalDateTime', () {
      // Same day as the text one, whatever the time zone.
      var day = CalendarDay.fromLocalDateTime(DateTime(2020, 1, 1, 23, 30));
      expect(day, CalendarDay.fromText('2020-01-01'));
      expect(day.text, '2020-01-01');
      expect(day.dateTime.isUtc, isTrue);
      expect(day.nextDay().text, '2020-01-02');
      expect(
        CalendarDay.fromLocalDateTime(DateTime(2020, 1, 1)),
        CalendarDay.fromLocalDateTime(DateTime(2020, 1, 1, 12)),
      );
    });
    test('nextDay', () {
      var day = CalendarDay.today();

      for (var i = 0; i < 1500; i++) {
        //print(day);
        var nextDay = day.nextDay();
        expect(nextDay, isNot(day));
      }
    });
    test('addDays', () {
      var day = CalendarDay.today();
      expect(day.addDays(3), day.nextDay().nextDay().nextDay());
      expect(day.addDays(-3), day.previousDay().previousDay().previousDay());
      expect(day.addDays(3000).addDays(-3000), day);
    });
    test('dayTimeToDateTime', () {
      expect(
        dayTimeToDateTime(
          CalendarDay(text: '2021-05-07'),
          CalendarTime(text: '26:40'),
        ).toIso8601String(),
        '2021-05-08T02:40:00.000Z',
      );
      expect(
        dayTimeToLocalDateTime(
          CalendarDay(text: '2021-05-07'),
          CalendarTime(text: '26:40'),
        ).toIso8601String(),
        '2021-05-08T02:40:00.000',
      );
    });
  });
}
