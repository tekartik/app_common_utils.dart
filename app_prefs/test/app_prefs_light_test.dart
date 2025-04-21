import 'package:tekartik_app_common_prefs/app_prefs_light.dart';
import 'package:test/test.dart';

void main() async {
  group('app_prefs_light', () {
    test('int', () async {
      var prefs = prefsLight;
      var value = (await prefs.getInt('value')) ?? 0;
      await prefs.setInt('value', ++value);
      // print('prefs set to $value');
      // Should increment at each test
    });
  });
}
