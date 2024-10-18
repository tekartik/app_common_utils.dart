import 'package:tekartik_app_common_prefs/app_prefs_async.dart';
import 'package:test/test.dart';

void main() async {
  group('app_prefs_sync', () {
    test('default', () async {
      var prefs = await prefsAsyncFactory.openPreferences('test_prefs.db');
      var value = await prefs.getInt('value') ?? 0;
      await prefs.setInt('value', ++value);
      // print('prefs set to $value');
      // Should increment at each test
    });
    test('doc', () async {
      // Get the default persistent prefs factory.
      var prefsFactory = getPrefsAsyncFactory();
      var prefs = await prefsFactory.openPreferences('my_shared_prefs');

// Once you have a [Prefs] object ready, use it. You can keep it open.
      await prefs.setInt('value', 26);
      var title = await prefs.getString('title');

      {
// For Windows/Linux support you can add package name to find a shared
// location on the file system
        var prefsFactory = getPrefsAsyncFactory(packageName: 'my.package.name');

        expect(prefsFactory, isNotNull);
      }

      // Memory
      {
        // In memory prefs factory.
        var prefsFactory = newPrefsAsyncFactoryMemory();
        var prefs = await prefsFactory.openPreferences('test_prefs.db');
        expect(await prefs.getInt('value'), isNull);
        await prefs.setInt('value', 1);
        expect(await prefs.getInt('value'), 1);
      }

      // ignore: unnecessary_statements
      title;
    });
  });
}
