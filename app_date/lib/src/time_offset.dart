//import 'package:quiver/strings.dart';

import 'package:tekartik_common_utils/date_time_utils.dart';
import 'package:tekartik_common_utils/string_utils.dart';

int dayOffsetLocalToUtc(int localDayOffset) {
  return localDayOffset - DateTime.now().timeZoneOffset.inMilliseconds;
}

int dayOffsetUtcToLocal(int utcDayOffset) {
  return utcDayOffset + DateTime.now().timeZoneOffset.inMilliseconds;
}

/// Time offwet typically between -99:99 and 99:99
class TimeOffset {
  /// Hour
  int hour;

  /// minute.
  int minute;

  int get milliseconds => (hour * 60 + minute) * 60 * 1000;

  TimeOffset([this.hour = 0, this.minute = 0]) {
    while (minute < 0) {
      hour -= 1;
      minute += 60;
    }
    while (minute >= 60) {
      hour += 1;
      minute -= 60;
    }
  }

  @override
  int get hashCode => hour + minute * 13;

  @override
  bool operator ==(Object other) {
    return other is TimeOffset && other.hour == hour && other.minute == minute;
  }

  @override
  String toString() {
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
