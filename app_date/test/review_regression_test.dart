import 'package:tekartik_app_date/calendar_day.dart';
import 'package:tekartik_app_date/calendar_time.dart';
import 'package:test/test.dart';

/// Regression tests of the 2026-11-09 review.
void main() {
  test('CalendarTime negative text keeps its sign', () {
    expect(CalendarTime(text: '-0:30').seconds, -1800);
    expect(CalendarTime(text: '-0:30').text, '-00:30');
    expect(CalendarTime(text: '-1:30').seconds, -5400);
    // 'HHMM' form, as '0130'.
    expect(CalendarTime(text: '-0130').seconds, -5400);
    expect(CalendarTime(text: '0130').seconds, 5400);
  });
  test('dayTimeToLocalDateTime is the wall clock time', () {
    // Daylight saving time change days in Europe and in the US: an hour off
    // when the local time zone changes that day (run with TZ=Europe/Paris).
    for (var text in ['2026-03-29', '2026-10-25', '2026-03-08', '2026-11-01']) {
      var day = CalendarDay(text: text);
      var dateTime = dayTimeToLocalDateTime(day, CalendarTime(text: '10:00'));
      expect(dateTime.isUtc, isFalse);
      expect(
        dateTime,
        DateTime(day.dateTime.year, day.dateTime.month, day.dateTime.day, 10),
      );
      expect(dateTime.hour, 10);
    }
  });
}
