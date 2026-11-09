// ignore_for_file: avoid_print

import 'package:tekartik_app_date/calendar_day.dart';
import 'package:tekartik_app_date/calendar_time.dart';
import 'package:tekartik_app_date/date_time_utils.dart';
import 'package:tekartik_app_date/time_offset.dart';

void main() {
  // A date, no time and no time zone, stored as text.
  var day = CalendarDay(text: '2024-02-28');
  print(day.nextDay().nextDay().text); // 2024-03-01
  // The user's date (CalendarDay.today() is the UTC date).
  var today = CalendarDay.fromLocalDateTime(DateTime.now());
  print(today.compareTo(today.addDays(1)) < 0); // true, days sort

  // A time of day in seconds from midnight, it can go past 24:00.
  var start = CalendarTime(text: '22:30');
  var end = parseEndCalendarTimeOrNull('22:30-26:40')!;
  print(end.text); // 26:40
  print(Duration(seconds: end.seconds - start.seconds).inMinutes); // 250

  // Day + time: a local wall clock time, or the same numbers in UTC.
  print(dayTimeToLocalDateTime(day, end)); // 2024-02-29 02:40:00.000
  print(dayTimeToDateTime(day, start)); // 2024-02-28 22:30:00.000Z

  // An offset: compute with seconds (see TimeOffset.text).
  var offset = TimeOffset.fromSeconds(-90 * 60);
  print(start.addOffset(offset).text); // 21:00

  // A file name safe timestamp: backup_20231001T123045.db
  var dateTime = DateTime.utc(2023, 10, 1, 12, 30, 45);
  print('backup_${dateTime.sanitizeToSeconds()}.db');
}
