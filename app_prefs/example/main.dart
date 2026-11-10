// ignore_for_file: avoid_print

import 'package:tekartik_app_common_prefs/app_prefs_async.dart';

/// Counts the launches of a program, in
/// `<userAppDataPath>/com.example.app_prefs_example/databases/settings` on
/// io, localStorage on the web.
Future<void> main() async {
  var factory = getPrefsAsyncFactory(
    packageName: 'com.example.app_prefs_example',
  );
  var prefs = await factory.openPreferences(
    'settings',
    version: 1,
    onVersionChanged: (prefs, oldVersion, newVersion) async {
      if (oldVersion < 1) {
        await prefs.setString('theme', 'light');
      }
    },
  );
  var count = (await prefs.getInt('launchCount') ?? 0) + 1;
  await prefs.setInt('launchCount', count);
  print('launch #$count, theme ${await prefs.getString('theme')}');
  await prefs.close();
}
