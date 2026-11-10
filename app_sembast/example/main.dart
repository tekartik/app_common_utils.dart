// ignore_for_file: avoid_print

import 'package:tekartik_app_sembast/sembast.dart';

/// Created once, kept for the whole app.
///
/// On Linux, Windows and macOS the databases are in
/// `<userAppDataPath>/com.example.my_app/databases` (`~/.config` or
/// `%APPDATA%`); IndexedDB on the web.
final databaseFactory = getDatabaseFactory(packageName: 'com.example.my_app');

/// Stores are declared globally.
final settingStore = StoreRef<String, int>.main();
final noteStore = intMapStoreFactory.store('note');

/// Run it twice: the launch count and the notes grow.
Future<void> main() async {
  // Open once, keep it open.
  var db = await databaseFactory.openDatabase('my_app.db');

  var launchCount = await db.transaction((txn) async {
    var count = (await settingStore.record('launchCount').get(txn) ?? 0) + 1;
    await settingStore.record('launchCount').put(txn, count);
    await noteStore.add(txn, {'title': 'note $count'});
    return count;
  });
  print('launch $launchCount');

  var notes = await noteStore.find(
    db,
    finder: Finder(sortOrders: [SortOrder(Field.key, false)], limit: 2),
  );
  print('last notes: ${notes.map((note) => note['title']).toList()}');

  // Not needed in an app: keep it open.
  await db.close();
}
