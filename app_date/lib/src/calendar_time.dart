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

  // Handle 11:00 and 1100
  CalendarTime({String? text, int? seconds}) {
    if (seconds != null) {
      _seconds = seconds;
    } else if (text != null) {
      try {
        late List<String> parts;

        if (text.length == 4) {
          parts = [text.substring(0, 2), text.substring(2, 4)];
          var hours = int.tryParse(parts[0]);
          var minutes = int.tryParse(parts[1]);
          if (hours != null && minutes != null) {
            _seconds = (hours * 60 + minutes) * 60;
            return;
          }
        }
        parts = text.split(':');
        var hourPart = parts[0];
        var hours = parseInt(hourPart)!;
        _seconds = hours * 60 * 60;

        var negative = (_seconds < 0);
        if (negative) {
          _seconds = -_seconds;
        }
        if (parts.length > 1) {
          _seconds += parseInt(parts[1])! * 60;
          if (parts.length > 2) {
            _seconds += parseInt(parts[2])!;
          }
        }

        if (negative) {
          _seconds = -_seconds;
        }
      } catch (e) {
        throw ArgumentError.value('invalid $text $e');
      }
    } else {
      throw ArgumentError.notNull('text and seconds');
    }
  }

  /// From any date time, pick the correct one
  factory CalendarTime.fromDateTime(DateTime dateTime) {
    return CalendarTime(
        seconds:
            ((dateTime.hour * 60) + dateTime.minute) * 60 + dateTime.second);
  }

  @override
  int compareTo(CalendarTime other) => _seconds - other._seconds;

  @override
  String toString() => 'Time($text)';

  String get text {
    if (isNegative) {
      return '-${negative.text}';
    }
    var minutes = hourMinutes;
    var minuteSeconds = this.minuteSeconds;
    return '${from2Digits(hours)}:${from2Digits(minutes)}${minuteSeconds == 0 ? '' : ':${from2Digits(minuteSeconds)}'}';
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
