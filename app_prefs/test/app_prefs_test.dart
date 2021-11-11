import 'package:tekartik_app_common_prefs/app_prefs.dart';
import 'package:test/test.dart';

void main() async {
  group('app_prefs', () {
    test('default', () async {
      var prefs = await prefsFactory.openPreferences('test_prefs.db');
      var value = prefs.getInt('value') ?? 0;
      prefs.setInt('value', ++value);
      // print('prefs set to $value');
      // Should increment at each test
    });
    test('doc', () async {
      // Get the default persistent prefs factory.
      var prefsFactory = getPrefsFactory();
      var prefs = await prefsFactory.openPreferences('my_shared_prefs');

// Once you have a [Prefs] object ready, use it. You can keep it open.
      prefs.setInt('value', 26);
      var title = prefs.getString('title');

      {
// For Windows/Linux support you can add package name to find a shared
// location on the file system
        var prefsFactory = getPrefsFactory(packageName: 'my.package.name');

        expect(prefsFactory, isNotNull);
      }

      // Memory
      {
        // In memory prefs factory.
        var prefsFactory = newPrefsFactoryMemory();
        var prefs = await prefsFactory.openPreferences('test_prefs.db');
        expect(prefs.getInt('value'), isNull);
        prefs.setInt('value', 1);
        expect(prefs.getInt('value'), 1);
      }

      // ignore: unnecessary_statements
      title;
    });
  });
}
