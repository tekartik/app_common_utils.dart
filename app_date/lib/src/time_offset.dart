//import 'package:quiver/strings.dart';

import 'package:tekartik_common_utils/string_utils.dart';

int dayOffsetLocalToUtc(int localDayOffset) {
  return localDayOffset - DateTime.now().timeZoneOffset.inMilliseconds;
}

int dayOffsetUtcToLocal(int utcDayOffset) {
  return utcDayOffset + DateTime.now().timeZoneOffset.inMilliseconds;
}

/// Time offset typically between -99:99 and 99:99
class TimeOffset {
  late int _hour;
  late int _minute;

  /// Hour
  int get hour => _hour;

  /// minute.
  int get minute => _minute;

  int get milliseconds => (hour * 60 + minute) * 60 * 1000;
  int get seconds => milliseconds ~/ 1000;

  TimeOffset([int hour = 0, int minute = 0]) {
    while (minute < 0) {
      hour -= 1;
      minute += 60;
    }
    while (minute >= 60) {
      hour += 1;
      minute -= 60;
    }
    _hour = hour;
    _minute = minute;
  }

  @override
  int get hashCode => hour + minute * 13;

  @override
  bool operator ==(Object other) {
    return other is TimeOffset && other.hour == hour && other.minute == minute;
  }

  /// positive
  TimeOffset._fromPositiveSeconds(int seconds) {
    _hour = seconds ~/ 3600;
    _minute = (seconds - hour * 3600) ~/ 60;
  }

  /// positive
  factory TimeOffset._fromNegativeSeconds(int seconds) {
    var tmp = TimeOffset._fromPositiveSeconds(-seconds);
    return TimeOffset(-tmp.hour, -tmp.minute);
  }

  /// positive
  factory TimeOffset.fromSeconds(int seconds) {
    if (seconds >= 0) {
      return TimeOffset._fromPositiveSeconds(seconds);
    } else {
      return TimeOffset._fromNegativeSeconds(seconds);
    }
  }
  @override
  String toString() {
    return 'TimeOffset($text)';
  }

  String get text {
    return "${hour < 0 ? '-' : ''}${hour.abs().toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}";
  }

  static TimeOffset parse(String? text) {
    var minute = 0;
    var hour = 0;
    try {
      if (!stringIsEmpty(text)) {
        var parts = text!.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      }
    } catch (_) {}
    return TimeOffset(hour, minute);
  }
}
