import 'package:tekartik_common_utils/date_time_utils.dart';
import 'package:tekartik_common_utils/int_utils.dart';

String from2Digits(int value) {
  var sb = StringBuffer();
  value %= 100;

  sb.write(value ~/ 10);
  sb.write(value % 10);
  return sb.toString();
}

class CalendarTime implements Comparable<CalendarTime> {
  late int _seconds; // in seconds from midnight
  int get seconds => _seconds;

  // Handle 11:00 and 1100
  CalendarTime({String? text, int? seconds}) {
    if (seconds != null) {
      _seconds = seconds;
    } else if (text != null) {
      try {
        List<String> parts;
        if (text.length == 4) {
          parts = [text.substring(0, 2), text.substring(2, 4)];
        } else {
          parts = text.split(':');
        }
        _seconds = parseInt(parts[0])! * 60 * 60;
        if (parts.length > 1) {
          _seconds += parseInt(parts[1])! * 60;
          if (parts.length > 2) {
            _seconds += parseInt(parts[2])!;
          }
        }
      } catch (e) {
        throw ArgumentError.value('invalid $text $e');
      }
    } else {
      throw ArgumentError.notNull('text and seconds');
    }
  }

  @override
  int compareTo(CalendarTime other) => _seconds - other._seconds;

  @override
  String toString() {
    var hours = (_seconds ~/ 3600) % 24;
    var minutes = (_seconds ~/ 60) % 60;
    return '${from2Digits(hours)}:${from2Digits(minutes)}';
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
