import 'package:tekartik_app_common_utils/app.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

void main() {
  group('app', () {
    test('app', () {
      expect(version, greaterThan(Version(0,0,0)));
    });
  });
}
