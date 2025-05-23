import 'package:tekartik_common_utils/date_time_utils.dart';

import 'calendar_time.dart';

/// Calendar day
class CalendarDay implements Comparable<CalendarDay> {
  late final DateTime _dateTime;

  /// Today
  factory CalendarDay.today() {
    return CalendarDay.fromTimestamp(DateTime.timestamp());
  }
  CalendarDay.fromTimestamp(DateTime dateTime) {
    assert(dateTime.isUtc);
    _dateTime = DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
  }
  CalendarDay.fromLocalDateTime(DateTime dateTime) {
    assert(!dateTime.isUtc);
    _dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// From '2000-01-01'
  CalendarDay.fromText(String text) {
    var dateTime = parseDateTime(text);
    if (dateTime != null) {
      _dateTime = DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
    } else {
      throw ArgumentError('$text $_dateTime');
    }
  }

  /// Use either, [dateTime] takes precedence
  CalendarDay({String? text, DateTime? dateTime}) {
    dateTime ??= parseDateTime(text);
    if (dateTime != null) {
      _dateTime = DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
    } else {
      throw ArgumentError('CalendarDay(test: $text, dateTime: $dateTime)');
    }
  }

  /// UTC
  DateTime get dateTime => timestamp;
  DateTime get timestamp => _dateTime;

  /// Local
  DateTime get localDateTime =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  @override
  int compareTo(CalendarDay other) =>
      _dateTime.millisecondsSinceEpoch - other._dateTime.millisecondsSinceEpoch;

  @override
  String toString() => 'Day($text)';

  String get text => _dateTime.toIso8601String().substring(0, 10);

  @override
  int get hashCode => _dateTime.millisecondsSinceEpoch;

  /// Next day
  CalendarDay nextDay() {
    return addDays(1);
  }

  /// Add a number of days (or substract if negative)
  CalendarDay addDays(int days) {
    return CalendarDay.fromTimestamp(_dateTime.add(Duration(days: days)));
  }

  /// Previous day
  CalendarDay previousDay() {
    return CalendarDay.fromTimestamp(
      _dateTime.subtract(const Duration(days: 1)),
    );
  }

  @override
  bool operator ==(other) {
    if (other is CalendarDay) {
      return _dateTime.millisecondsSinceEpoch ==
          other._dateTime.millisecondsSinceEpoch;
    }
    return false;
  }
}

CalendarDay? parseCalendarDayOrNull(String? text) {
  if (text == null) {
    return null;
  }
  return parseCalendarDay(text);
}

CalendarDay? parseCalendarDay(String text) {
  try {
    return CalendarDay(text: text);
  } catch (_) {
    return null;
  }
}

// Return a time in the even timezone as UTC
DateTime dayTimeToDateTime(CalendarDay day, CalendarTime time) {
  var dateTime = day.dateTime;
  return dateTime.add(Duration(seconds: time.seconds));
}

DateTime dayTimeToLocalDateTime(CalendarDay day, CalendarTime time) {
  var dateTime = day.localDateTime;
  return dateTime.add(Duration(seconds: time.seconds));
}
