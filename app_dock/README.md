# tekartik_app_dock

One place for the data of a pure Dart app (command line tool, server, web
page), on the Dart VM and in the browser: give a `packageName` and get the
prefs, sdb (and sembast) database factories and a file system, each picked
for the platform at compile time.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_dock:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_dock
```

```dart
import 'package:tekartik_app_dock/fs.dart';
import 'package:tekartik_app_dock/prefs.dart';
import 'package:tekartik_app_dock/sdb.dart';

/// One value for the whole app, reverse dns style.
const packageName = 'com.example.my_app';

final noteStore = SdbStoreRef<int, SdbModel>('note');

Future<void> main() async {
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

  await db.close();
  await prefs.close();
}
```

See [example/main.dart](example/main.dart).

## Platforms

| | Dart VM (Linux, macOS, Windows) | Browser (dart2js, dart2wasm) |
|---|---|---|
| Location | `<userAppDataPath>/<packageName>`: `%APPDATA%` on Windows, `~/.config` elsewhere (`userAppDataPath` of process_run, `TEKARTIK_PROCESS_RUN_USER_APP_DATA_PATH` overrides it) | names prefixed by `<packageName>/` on the page origin |
| Prefs | sembast files | localStorage |
| sdb, sembast | sembast files in `<location>/sembast_databases` | IndexedDB |
| File system | `dart:io` (sandboxed) | IndexedDB (fs_shim) |

Without `packageName`, io paths are relative to the current directory and the
web uses the factories without prefix. Flutter desktop and web work too; on
Flutter Android/iOS use the Flutter packages of
[app_flutter_utils](https://github.com/tekartik/app_flutter_utils.dart)
instead (no user application data folder there).

## What to use

* `package:tekartik_app_dock/sdb.dart`: `dockGetSdbFactory({packageName})`,
  the sdb API of `idb_shim` (stores, indexes, transactions). Use it for new
  local databases.
* `package:tekartik_app_dock/prefs.dart`: `dockGetPrefsAsyncFactory` (every
  call returns a `Future`, same shape as on Flutter) and `dockGetPrefsFactory`
  (synchronous reads, writes saved in the background). One factory per
  `packageName`: calling them again returns the same factory.
* `package:tekartik_app_dock/fs.dart`: `dockGetAppDataFileSystem(packageName:)`,
  a fs_shim `FileSystem` rooted at the app data folder, and
  `dockGetAppDataPath({packageName})` (the folder itself, for display or other
  io tools).
* `package:tekartik_app_dock/sembast.dart`: `dockGetSembastDatabaseFactory`
  for existing sembast databases (new code: sdb).

## Common pitfalls

* Use the same `packageName` in every call: it is the only link between
  them.
* On io, sembast databases, sdb databases and prefs share the
  `sembast_databases` folder: one name used by two of them is one file. Give
  databases an extension (`notes.db`), prefs a plain name (`settings`).
* Open a database with a relative name (`notes.db`): an absolute path is
  moved below the app data folder.
* `databaseFactoryIo` and the other io only names re-exported by `sembast.dart`
  throw on the web: keep them out of shared code.
* Tests on the VM write in the real user folder: use a test `packageName`
  (`com.example.my_app_test`) and delete the databases first.
* Before 2026-11-10, two `dockGetPrefsFactory` calls on io gave two
  factories: the same prefs opened twice had two caches on one file.

## Agent skills

[skills/tekartik-app-dock-setup](skills/tekartik-app-dock-setup/SKILL.md).
