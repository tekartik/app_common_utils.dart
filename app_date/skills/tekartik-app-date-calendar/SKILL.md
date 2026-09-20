---
name: tekartik-app-date-calendar
description: >-
  Use when Dart code manipulates calendar dates without time (CalendarDay:
  today, fromText '2024-05-07', nextDay, previousDay, addDays, text, dateTime,
  localDateTime, parseCalendarDay, parseCalendarDayOrNull), times of day in
  seconds that may exceed 24h or be negative (CalendarTime: 'HH:MM', 'HHMM',
  'H:MM:SS', hours, minutes, fullHours, hourMinutes, minuteSeconds, addOffset,
  parseCalendarTimeOrNull, parseStartCalendarTimeOrNull,
  parseEndCalendarTimeOrNull), signed hour:minute offsets (TimeOffset, parse,
  fromSeconds), day plus time combination (dayTimeToDateTime,
  dayTimeToLocalDateTime) or file name safe timestamps
  (DateTime.sanitizeToSeconds) with tekartik_app_date.
---

# Calendar day, time and offset (tekartik_app_date)

`tekartik_app_date` is a small pure Dart package (VM, web, Flutter) with
three value types for scheduling code: `CalendarDay` (a date, no time, no
zone), `CalendarTime` (a time of day counted in seconds from midnight, that
can go past 24:00 or be negative) and `TimeOffset` (a signed hour:minute
duration), plus a `DateTime` extension.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_date:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_date
  ```
* One import per type: `package:tekartik_app_date/calendar_day.dart`,
  `package:tekartik_app_date/calendar_time.dart`,
  `package:tekartik_app_date/time_offset.dart` and
  `package:tekartik_app_date/date_time_utils.dart`.

### CalendarDay

* Build with `CalendarDay(text: '2024-05-07')`, `CalendarDay.fromText(text)`
  (accepts `2024-05-07`, `20240507` and any iso date-time, the time part is
  dropped), `CalendarDay(dateTime: dt)` (year, month and day of `dt` as
  given; `dateTime` wins over `text`), `CalendarDay.fromTimestamp(utc)`
  (asserts `isUtc`), `CalendarDay.fromLocalDateTime(local)` (asserts a
  local `DateTime`) and `CalendarDay.today()` (the UTC date of now; use
  `CalendarDay.fromLocalDateTime(DateTime.now())` for the user's local
  date). Constructors throw `ArgumentError` on unparsable input;
  `parseCalendarDay(text)` and `parseCalendarDayOrNull(text?)` return
  `null` instead.
* Read `text` (`yyyy-MM-dd`), `dateTime` / `timestamp` (midnight UTC) or
  `localDateTime` (midnight in the local zone). `toString()` is
  `Day(2024-05-07)`.
* Navigate with `nextDay()`, `previousDay()` and `addDays(n)` (negative to
  go back). Days are immutable and comparable (`compareTo`, `==`,
  `hashCode`): usable as map keys and sortable with `list.sort()`.
* Combine with a time: `dayTimeToDateTime(day, time)` returns a UTC
  `DateTime` (`day.dateTime` plus `time.seconds`),
  `dayTimeToLocalDateTime(day, time)` a local one; a time past 24:00 rolls
  into the next day.

### CalendarTime

* Build with `CalendarTime(text: '10:30')` or `CalendarTime(seconds: 37800)`
  (`seconds` wins; both null throws), `CalendarTime.fromText(text)`,
  `CalendarTime.fromSeconds(seconds)`, `CalendarTime.fromDateTime(dt)`
  (hour, minute and second of `dt`, in whatever zone `dt` is) and
  `CalendarTime.zero()`. Accepted texts: `HH:MM`, `HHMM` (exactly 4
  digits), `H`, `H:MM:SS`, hours past 24 (`26:40`) and a leading `-` for
  negative times. Anything else throws `ArgumentError`.
* `parseCalendarTimeOrNull(text)` (alias of `parseStartCalendarTimeOrNull`)
  parses the part before the first `-` of a `10:00-12:00` range and
  `parseEndCalendarTimeOrNull(text)` the part after it; both return `null`
  on failure. They split on `-`, so they cannot parse negative times.
* Read `seconds` (signed total), `minutes` and `hours` (signed totals,
  truncated toward zero), `fullHours` (floored hours: `-1:01` gives `-2`),
  `hourMinutes` and `minuteSeconds` (always `0..59`), `isNegative`,
  `isFullHours`, `isFullMinutes`, `negative` (the opposite time) and
  `text` (`HH:MM`, or `HH:MM:SS` when seconds are not zero, `-` prefix
  when negative; hours are never wrapped, `25:00` stays `25:00`).
  `toString()` is `Time(10:30)`.
* `time.addOffset(TimeOffset(1, 30))` shifts by an offset (negative offsets
  subtract). Times are comparable with `compareTo`; `==` is not
  overridden, compare `seconds`.

### TimeOffset

* `TimeOffset([hour = 0, minute = 0])` normalizes `minute` into `0..59` by
  carrying into `hour`: `TimeOffset(1, -1) == TimeOffset(0, 59)`,
  `TimeOffset(-2, 61) == TimeOffset(-1, 1)`. The duration is
  `hour * 60 + minute` minutes (`seconds`, `milliseconds`), so
  `TimeOffset(-1, 1)` is minus 59 minutes.
* `TimeOffset.parse('-2:61')` (null, empty or invalid text gives a zero
  offset) and `TimeOffset.fromSeconds(seconds)` (negative allowed).
* `text` prints the sign, `hour.abs()` and `minute` as stored (`-01:01`
  for `TimeOffset(-1, 1)`, `-02:58` for `TimeOffset.fromSeconds(-3720)`):
  it is not the absolute duration. Use `seconds` for arithmetic and `==` /
  `hashCode` for comparisons.

### DateTime extension

* `dateTime.sanitizeToSeconds()` from `date_time_utils.dart` formats
  `yyyyMMddTHHmmss` (`20231001T123045`), no zone, for file names.
* Tests: `dart test` (also runs with `-p chrome`).

## Examples

### Iterate, parse and sort days

```dart
import 'package:tekartik_app_date/calendar_day.dart';

/// Every day from [from] to [to] included, as text.
List<String> daysBetween(CalendarDay from, CalendarDay to) {
  var days = <String>[];
  for (var day = from; day.compareTo(to) <= 0; day = day.nextDay()) {
    days.add(day.text);
  }
  return days;
}

void main() {
  var today = CalendarDay.fromLocalDateTime(DateTime.now());
  print(daysBetween(today, today.addDays(2))); // 3 days

  var day = parseCalendarDay('2024-02-28');
  print(day?.nextDay().nextDay()); // Day(2024-03-01)
  print(parseCalendarDayOrNull('not a day')); // null

  // Sorting and map keys work by value.
  var sorted = [CalendarDay(text: '20240310'), CalendarDay(text: '2024-03-01')]
    ..sort();
  print(sorted.first.text); // 2024-03-01
}
```

### Time slots on a day, past midnight

```dart
import 'package:tekartik_app_date/calendar_day.dart';
import 'package:tekartik_app_date/calendar_time.dart';

class Slot {
  final CalendarDay day;
  final CalendarTime start;
  final CalendarTime end;

  Slot(this.day, String range)
    : start = parseStartCalendarTimeOrNull(range)!,
      end = parseEndCalendarTimeOrNull(range)!;

  /// UTC start instant.
  DateTime get startUtc => dayTimeToDateTime(day, start);

  /// Local end instant; an end past 24:00 lands on the next day.
  DateTime get endLocal => dayTimeToLocalDateTime(day, end);

  Duration get duration => Duration(seconds: end.seconds - start.seconds);
}

void main() {
  var slot = Slot(CalendarDay(text: '2021-05-07'), '22:30-26:40');
  print(slot.startUtc.toIso8601String()); // 2021-05-07T22:30:00.000Z
  print(slot.endLocal.toIso8601String()); // 2021-05-08T02:40:00.000
  print(slot.duration.inMinutes); // 250
  print(slot.end.text); // 26:40
  print(slot.end.hours); // 26
  print(CalendarTime.fromSeconds(123456).text); // 34:17:36
  print(CalendarTime(text: '-1:01').fullHours); // -2
}
```

### Offsets and file name timestamps

```dart
import 'package:tekartik_app_date/calendar_time.dart';
import 'package:tekartik_app_date/date_time_utils.dart';
import 'package:tekartik_app_date/time_offset.dart';

void main() {
  var offset = TimeOffset.parse('1:30');
  print(offset.text); // 01:30
  print(CalendarTime(text: '10:00').addOffset(offset).text); // 11:30
  print(CalendarTime(text: '10:00').addOffset(TimeOffset(-1, -2)).text); // 08:58

  // Normalization: minutes are kept in 0..59.
  print(TimeOffset(-2, 61) == TimeOffset(-1, 1)); // true
  print(TimeOffset(-1, 1).seconds); // -3540 (minus 59 minutes)
  print(TimeOffset.fromSeconds(-3720).seconds); // -3720

  // File name safe timestamp.
  var name = 'backup_${DateTime.now().sanitizeToSeconds()}.db';
  print(name); // backup_20231001T123045.db
}
```
