import 'package:tekartik_app_dock/prefs.dart';
import 'package:test/test.dart';

var testPackageName = 'com.tekartik.app_dock_test';

void main() {
  group('prefs', () {
    test('prefs', () async {
      var factory = dockGetPrefsFactory(packageName: testPackageName);
      var prefs = await factory.openPreferences('test_prefs');
      prefs.setInt('value', 1);
      expect(prefs.getInt('value'), 1);
      await prefs.close();
    });
    test('prefs async', () async {
      var factory = dockGetPrefsAsyncFactory(packageName: testPackageName);
      var prefs = await factory.openPreferences('test_prefs_async');
      await prefs.setInt('value', 2);
      expect(await prefs.getInt('value'), 2);
      await prefs.close();
    });
  });
}
