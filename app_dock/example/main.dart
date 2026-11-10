// ignore_for_file: avoid_print

import 'package:tekartik_app_dock/fs.dart';
import 'package:tekartik_app_dock/prefs.dart';
import 'package:tekartik_app_dock/sdb.dart';

/// One value for the whole app, reverse dns style.
const packageName = 'com.example.my_app';

final noteStore = SdbStoreRef<int, SdbModel>('note');

/// Run it twice: the launch count and the notes grow.
///
/// On the VM the data is in `dockGetAppDataPath(packageName: packageName)`
/// (`~/.config/com.example.my_app` on Linux and macOS).
Future<void> main() async {
  print('data in ${dockGetAppDataPath(packageName: packageName)}');

  // Preferences.
  var prefs = await dockGetPrefsAsyncFactory(
    packageName: packageName,
  ).openPreferences('settings');
  var launchCount = (await prefs.getInt('launchCount') ?? 0) + 1;
  await prefs.setInt('launchCount', launchCount);
  print('launch $launchCount');

  // A local database (sdb: IndexedDB like API).
  var db = await dockGetSdbFactory(packageName: packageName).openDatabase(
    'notes.db',
    options: SdbOpenDatabaseOptions(
      version: 1,
      schema: SdbDatabaseSchema(
        stores: [noteStore.schema(autoIncrement: true)],
      ),
    ),
  );
  await noteStore.add(db, {'title': 'note $launchCount'});
  print('${await noteStore.count(db)} notes');

  // Files.
  var fs = dockGetAppDataFileSystem(packageName: packageName);
  var file = fs.file(fs.path.join('exports', 'last.txt'));
  await file.parent.create(recursive: true);
  await file.writeAsString('launch $launchCount');
  print('${file.path}: ${await file.readAsString()}');

  await db.close();
  await prefs.close();
}
