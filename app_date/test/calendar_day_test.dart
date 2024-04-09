import 'package:tekartik_app_date/calendar_day.dart';
import 'package:test/test.dart';

void main() {
  group('day', () {
    test('day', () {
      var day = CalendarDay(text: '2012-01-23');
      expect(day.toString(), '2012-01-23');

      day = CalendarDay(text: '20120123');
      expect(day.toString(), '2012-01-23');
    });
    test('nextDay', () {
      var day = CalendarDay.today();

      for (var i = 0; i < 1500; i++) {
        print(day);
        var nextDay = day.nextDay();
        expect(nextDay, isNot(day));
      }
    });
  });
}
