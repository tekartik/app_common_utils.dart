import 'package:tekartik_app_date/time_offset.dart';
import 'package:tekartik_common_utils/int_utils.dart';

String from2Digits(int value) {
  if (value < 0) {
    return '-${from2Digits(-value)}';
  }
  var sb = StringBuffer();
  value %= 100;

  sb.write(value ~/ 10);
  sb.write(value % 10);
  return sb.toString();
}

/// A time of day in [seconds] from midnight (`10:30`), that can go past
/// 24:00 (`26:40`) or be negative (`-0:30`): also usable as a duration.
///
/// No `==`: compare [seconds] or use [compareTo].
class CalendarTime implements Comparable<CalendarTime> {
  late int _seconds; // in seconds from midnight
  int get seconds => _seconds;
  bool get isNegative => seconds < 0;

  bool get isFullHours => (seconds % 3600) == 0;
  bool get isFullMinutes => (seconds % 60) == 0;

  /// Opposite
  CalendarTime get negative => CalendarTime(seconds: -seconds);

  /// Total hours
  int get hours => (_seconds ~/ 3600);

  int get fullHours =>
      isFullHours ? hours : (isNegative ? -(negative.hours + 1) : hours);

  /// Total minues
  int get minutes => (_seconds ~/ 60);

  /// Minutes in the hour (>=0 <60)
  int get hourMinutes => isFullMinutes
      ? (minutes % 60)
      : (isNegative ? ((minutes % 60) - 1) : (minutes % 60));

  /// Seconds in the minute (>=0 <60)
  int get minuteSeconds => seconds % 60;

  /// From '10:00', '1000', '10', '1:01:12' or '-0:30' (the sign applies to
  /// the whole time).
  CalendarTime.fromText(String text) {
    try {
      var negative = text.startsWith('-');
      _seconds = _parseUnsignedSeconds(negative ? text.substring(1) : text);
      if (negative) {
        _seconds = -_seconds;
      }
    } catch (e) {
      throw ArgumentError.value('invalid $text $e');
    }
  }

  /// Seconds of 'HHMM' or 'H[:M[:S]]'.
  static int _parseUnsignedSeconds(String text) {
    if (text.length == 4) {
      var hours = int.tryParse(text.substring(0, 2));
      var minutes = int.tryParse(text.substring(2, 4));
      if (hours != null && minutes != null) {
        return (hours * 60 + minutes) * 60;
      }
    }
    var parts = text.split(':');
    var seconds = parseInt(parts[0])! * 60 * 60;
    if (parts.length > 1) {
      seconds += parseInt(parts[1])! * 60;
      if (parts.length > 2) {
        seconds += parseInt(parts[2])!;
      }
    }
    return seconds;
  }

  CalendarTime.fromSeconds(int seconds) {
    _seconds = seconds;
  }
  // Handle 11:00 and 1100
  factory CalendarTime({String? text, int? seconds}) {
    if (seconds != null) {
      return CalendarTime.fromSeconds(seconds);
    } else if (text != null) {
      return CalendarTime.fromText(text);
    } else {
      throw ArgumentError.notNull('text and seconds');
    }
  }

  /// From any date time, pick the correct one
  factory CalendarTime.fromDateTime(DateTime dateTime) {
    return CalendarTime.fromSeconds(
      ((dateTime.hour * 60) + dateTime.minute) * 60 + dateTime.second,
    );
  }
  CalendarTime.zero() {
    _seconds = 0;
  }

  @override
  int compareTo(CalendarTime other) => _seconds - other._seconds;

  @override
  String toString() => 'Time($text)';

  /// `HH:MM`, or `HH:MM:SS` when the seconds are not zero, `-` first when
  /// negative (only 2 digits of hours are printed).
  String get text {
    if (isNegative) {
      return '-${negative.text}';
    }
    var minutes = hourMinutes;
    var minuteSeconds = this.minuteSeconds;
    return '${from2Digits(hours)}:${from2Digits(minutes)}${minuteSeconds == 0 ? '' : ':${from2Digits(minuteSeconds)}'}';
  }

  CalendarTime addOffset(TimeOffset offset) {
    return CalendarTime(seconds: seconds + offset.milliseconds ~/ 1000);
  }
}

String twoDigitNumber(int number) {
  return (number < 10) ? '0$number' : '$number';
}

// 25:00 => 1:00
String secondsToTimeString(int seconds) {
  var hours = seconds ~/ 3600;
  var minutes = (seconds - hours * 3600) ~/ 60;
  if (hours >= 24) {
    hours -= 24;
  }
  return '${twoDigitNumber(hours)}:${twoDigitNumber(minutes)}';
}

/// For start-end format
CalendarTime? parseCalendarTimeOrNull(String text) {
  return parseStartCalendarTimeOrNull(text);
}

/// For start-end format
CalendarTime? parseStartCalendarTimeOrNull(String text) {
  try {
    return CalendarTime(text: text.split('-').first);
  } catch (_) {
    return null;
  }
}

/// For start-end format
CalendarTime? parseEndCalendarTimeOrNull(String text) {
  try {
    return CalendarTime(text: text.split('-')[1]);
  } catch (_) {
    return null;
  }
}
