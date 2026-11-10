import 'package:tekartik_app_dock/prefs.dart';
import 'package:test/test.dart';

var testPackageName = 'com.tekartik.app_dock_test';

void main() {
  group('review regression', () {
    // Each dockGetPrefsFactory call used to create a new sembast prefs factory
    // on io: since tekartik_prefs_sembast keeps its opened prefs per factory,
    // two calls opening the same name got two instances on one database
    // (stale reads, and closing one closed the database of the other).
    test('prefs, same package name, same prefs', () async {
      var name = 'review_shared_prefs';
      await dockGetPrefsFactory(
        packageName: testPackageName,
      ).deletePreferences(name);
      var prefs1 = await dockGetPrefsFactory(
        packageName: testPackageName,
      ).openPreferences(name);
      var prefs2 = await dockGetPrefsFactory(
        packageName: testPackageName,
      ).openPreferences(name);
      prefs1.setInt('value', 1);
      expect(prefs2.getInt('value'), 1);
      await prefs1.close();
      var prefs3 = await dockGetPrefsFactory(
        packageName: testPackageName,
      ).openPreferences(name);
      expect(prefs3.getInt('value'), 1);
      await prefs3.close();
      await dockGetPrefsFactory(
        packageName: testPackageName,
      ).deletePreferences(name);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('prefs async, same package name, same prefs', () async {
      var name = 'review_shared_prefs_async';
      await dockGetPrefsAsyncFactory(
        packageName: testPackageName,
      ).deletePreferences(name);
      // A factory kept by one part of the app...
      var factory = dockGetPrefsAsyncFactory(packageName: testPackageName);
      var prefs1 = await factory.openPreferences(name);
      await prefs1.setInt('value', 1);
      // ...and the same prefs opened and closed by another part.
      var prefs2 = await dockGetPrefsAsyncFactory(
        packageName: testPackageName,
      ).openPreferences(name);
      expect(await prefs2.getInt('value'), 1);
      await prefs2.close();
      // Opening it again from the kept factory gives a working prefs (it
      // used to give the first instance, whose database was closed).
      var prefs3 = await factory.openPreferences(name);
      expect(await prefs3.getInt('value'), 1);
      await prefs3.close();
      await dockGetPrefsAsyncFactory(
        packageName: testPackageName,
      ).deletePreferences(name);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
