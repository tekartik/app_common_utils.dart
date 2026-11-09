# tekartik_app_date

Calendar values for scheduling code, in pure Dart: `CalendarDay` (a date,
no time and no time zone, `2024-05-07`), `CalendarTime` (a time of day in
seconds from midnight, that can go past 24:00 or be negative, `26:40`),
`TimeOffset` (an hours and minutes shift) and a file name safe timestamp.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_date:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_date
```

```dart
import 'package:tekartik_app_date/calendar_day.dart';
import 'package:tekartik_app_date/calendar_time.dart';

void main() {
  var day = CalendarDay(text: '2024-02-28');
  print(day.addDays(2).text); // 2024-03-01
  var end = CalendarTime(text: '26:40'); // 02:40 the next day
  print(dayTimeToLocalDateTime(day, end)); // 2024-02-29 02:40:00.000
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser. No platform
setup. See [example/main.dart](example/main.dart).

## What to use

| Import | Main API | Use it to |
|---|---|---|
| `calendar_day.dart` | `CalendarDay` (`text`, `nextDay`, `addDays`, `compareTo`), `parseCalendarDayOrNull`, `dayTimeToDateTime`, `dayTimeToLocalDateTime` | store and compare a date, combine it with a time |
| `calendar_time.dart` | `CalendarTime` (`text`, `seconds`, `hours`, `addOffset`), `parseStartCalendarTimeOrNull`, `parseEndCalendarTimeOrNull` | a time of day or a duration (`10:30`, `1030`, `26:40`, `-0:30`), a `10:00-12:00` range |
| `time_offset.dart` | `TimeOffset` (`seconds`, `parse`, `fromSeconds`) | shift a time by hours and minutes |
| `date_time_utils.dart` | `DateTime.sanitizeToSeconds()` | `20231001T123045` for a file name |

## Common pitfalls

* `CalendarDay.today()` is the UTC date: at 00:30 in Paris it is still
  yesterday. Use `CalendarDay.fromLocalDateTime(DateTime.now())` for the
  user's date.
* `dayTimeToDateTime` reads the day and the time as UTC; use
  `dayTimeToLocalDateTime` for a local wall clock time (also right on
  daylight saving time change days since 2026-11-09, one hour off before).
* `CalendarTime` has no `==`: compare `seconds` or use `compareTo`.
* `CalendarTime.text` prints 2 digits of hours: `100:00` prints `00:00`.
* The range parsers split on `-`: a range cannot hold a negative time.
* `TimeOffset` keeps its minutes in `0..59` by carrying into a negative
  hour: `TimeOffset.fromSeconds(-5400).text` (minus 90 minutes) is
  `-02:30`, and `TimeOffset.parse('-01:30')` is minus 30 minutes, not 90.
  `text` and `parse` read each other back, but never write a negative
  offset by hand: compute with `seconds`.
* A date-time text with a zone offset gives the date of its UTC instant:
  `CalendarDay(text: '2024-05-07T23:30:00-05:00').text` is `2024-05-08`.

## Agent skills

[skills/tekartik-app-date-calendar](skills/tekartik-app-date-calendar/SKILL.md).
