import 'package:tekartik_app_date/time_offset.dart';
import 'package:test/test.dart';

void main() {
  test('time_offset', () {
    var timeOffset = TimeOffset();
    expect(timeOffset.toString(), 'TimeOffset(00:00)');
    expect(TimeOffset(1, -1), TimeOffset(0, 59));
    expect(TimeOffset(-2, 61), TimeOffset(-1, 1));
    expect(TimeOffset(-1, 1).text, '-01:01');
    expect(TimeOffset(-1, 1).toString(), 'TimeOffset(-01:01)');
    expect(TimeOffset.parse('-2:61').text, '-01:01');
  });
  test('seconds time_offset', () {
    expect(TimeOffset.fromSeconds(3720).seconds, 3720);
    expect(TimeOffset.fromSeconds(-3720).seconds, -3720);
    expect(TimeOffset.fromSeconds(-3720).text, '-02:58');
  });
}
