import 'package:tekartik_app_date/time_offset.dart';
import 'package:test/test.dart';

void main() {
  test('time_offset', () {
    var timeOffset = TimeOffset();
    expect(timeOffset.toString(), '00:00');
    expect(TimeOffset(1, -1), TimeOffset(0, 59));
    expect(TimeOffset(-2, 61), TimeOffset(-1, 1));
    expect(TimeOffset(-1, 1).toString(), '-01:01');
    expect(TimeOffset.parse('-2:61').toString(), '-01:01');
  });
}
