---
name: tekartik-app-dock-setup
description: >-
  Use when a pure Dart application (command line tool, server side script or
  web page, not Flutter specific) needs a per-application storage location
  that works identically on the VM and in the browser with tekartik_app_dock:
  prefs (dockGetPrefsFactory, dockGetPrefsAsyncFactory), sembast databases
  (dockGetSembastDatabaseFactory, dockGetAppSembastDatabasesPath,
  dockSembastDatabasesDirPath), sdb databases (dockGetSdbFactory), file system
  (dockGetAppDataFileSystem, dockGetAppDataPath), the packageName sandbox
  (userAppDataPath/<packageName> on io, IndexedDB and localStorage names on
  the web) and the imports package:tekartik_app_dock/prefs.dart, sembast.dart,
  sdb.dart and fs.dart.
---

# App dock: prefs, sembast, sdb and fs on VM and web (tekartik_app_dock)

`tekartik_app_dock` gives a Dart app one `packageName` based location for
its data and four factories that resolve to the right implementation at
compile time: `dart:io` files under the user's application data directory
on the VM, IndexedDB / localStorage in the browser. Importing any of its
libraries is safe on every platform; on an unsupported one the getters throw
`UnimplementedError`.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_dock:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_dock
  ```
  It depends on `sembast`, `sembast_web`, `idb_shim`, `fs_shim`,
  `tekartik_prefs` (plus `_sembast` and `_browser`) and `process_run`;
  declare the ones you import directly as well.
* Pick one `packageName` constant per application, reverse-dns style
  (`com.example.my_app`), and pass the same value to every `dockGet*` call.
  On io it selects `join(userAppDataPath, packageName)` (`userAppDataPath`
  from `process_run`: the per-user application data directory of the OS);
  on the web it prefixes the IndexedDB database, localStorage and file
  system names so several apps on one origin do not collide. With
  `packageName: null` io paths are relative to the current directory and
  the web uses the unsandboxed factories.
* `package:tekartik_app_dock/prefs.dart` (re-exports `tekartik_prefs`
  `prefs.dart` and `prefs_async.dart`): `dockGetPrefsFactory({packageName})`
  returns a `PrefsFactory` (`openPreferences(name)` gives a `Prefs` with a
  synchronous API: `getInt`, `setInt`, `getString`, `setString`, `getBool`,
  `setBool`, `getDouble`, `setDouble`, `getMap`, `setMap`, `getList`,
  `setList`, `remove`, `clear`, `keys`, `containsKey`, `close()`);
  `dockGetPrefsAsyncFactory({packageName})` returns a `PrefsAsyncFactory`
  (`PrefsAsync`, every call returns a `Future`). Prefer the async one in
  code shared with Flutter. On io both store sembast databases in the app
  databases directory, the web uses localStorage. They are distinct
  factories: do not open the same preferences name with both.
* `package:tekartik_app_dock/sembast.dart` (re-exports `sembast.dart` and
  `sembast_io.dart`): `dockGetSembastDatabaseFactory({packageName})` is
  `databaseFactoryIo` sandboxed in
  `dockGetAppSembastDatabasesPath(packageName:)` (`<app data>/` followed by
  `dockSembastDatabasesDirPath`, i.e. `sembast_databases`) on io and
  `databaseFactoryWeb` on the web. Open with relative names
  (`openDatabase('cache.db')`), never absolute paths. Do not touch the
  re-exported `databaseFactoryIo` in shared code: it throws on the web.
* `package:tekartik_app_dock/sdb.dart` (re-exports `idb_shim/sdb.dart`):
  `dockGetSdbFactory({packageName})` is `sdbFactoryIo` sandboxed in the
  same databases directory on io (one cached factory per `packageName`)
  and `sdbFactoryWeb` (IndexedDB) on the web. sdb needs a version and
  either a `schema` or an `onVersionChange` callback in
  `SdbOpenDatabaseOptions`.
* `package:tekartik_app_dock/fs.dart` (re-exports `fs_shim.dart` and
  `fs_memory.dart`): `dockGetAppDataFileSystem(packageName:)` returns a
  `FileSystem` rooted at the app data directory (`fileSystemIo.sandbox` on
  io, the IndexedDB based `fileSystemWeb.sandbox` on the web); use
  `fs.path.join`, `fs.directory`, `fs.file`, `create(recursive: true)`,
  `writeAsString`, `readAsString` with paths relative to that root.
  `dockGetAppDataPath({packageName})` is the underlying path (absolute on
  io, `/<packageName>` on the web) for display or for other io tools.
  Sembast and prefs files live in `sembast_databases/` under that root:
  keep your own files in another sub directory.
* Tests: put `platforms: [vm, chrome]` in `dart_test.yaml` and run
  `dart test`; use a dedicated `packageName` such as
  `com.example.my_app_test` and `deleteDatabase(name)` before opening so
  each run starts clean. `newFileSystemMemory()` from `fs.dart` gives an
  in memory `FileSystem` for pure logic tests. Guard VM-only code with
  `kDartIsWeb` from `package:tekartik_common_utils/env_utils.dart` or with
  `try { databaseFactoryIo; } on UnimplementedError catch (_) {}`.
* The README still shows `dbGet*` names and a bare `fs` getter; the public
  API is `dockGet*` and `dockGetAppDataFileSystem`.

## Examples

### Application storage bootstrap

```dart
import 'package:tekartik_app_dock/fs.dart';
import 'package:tekartik_app_dock/prefs.dart';
import 'package:tekartik_app_dock/sdb.dart';
import 'package:tekartik_app_dock/sembast.dart';

const packageName = 'com.example.my_app';

/// Everything the app persists, resolved for the current platform.
class AppStorage {
  final PrefsAsync prefs;
  final Database db;
  final SdbFactory sdbFactory;
  final FileSystem fs;

  AppStorage._(this.prefs, this.db, this.sdbFactory, this.fs);

  static Future<AppStorage> open() async {
    var prefs = await dockGetPrefsAsyncFactory(
      packageName: packageName,
    ).openPreferences('settings');
    var db = await dockGetSembastDatabaseFactory(
      packageName: packageName,
    ).openDatabase('app.db');
    var sdbFactory = dockGetSdbFactory(packageName: packageName);
    var fs = dockGetAppDataFileSystem(packageName: packageName);
    return AppStorage._(prefs, db, sdbFactory, fs);
  }

  Future<void> close() async {
    await prefs.close();
    await db.close();
  }
}

Future<void> main() async {
  print('data in ${dockGetAppDataPath(packageName: packageName)}');
  var storage = await AppStorage.open();

  // A file under the app data directory.
  var fs = storage.fs;
  await fs.directory('exports').create(recursive: true);
  var file = fs.file(fs.path.join('exports', 'last.txt'));
  await file.writeAsString('hello');
  print(await file.readAsString());

  await storage.close();
}
```

### Sync and async preferences

```dart
import 'package:tekartik_app_dock/prefs.dart';

const packageName = 'com.example.my_app';

/// Sync API: reads are immediate, writes are persisted for you.
Future<int> bumpLaunchCount() async {
  var prefs = await dockGetPrefsFactory(
    packageName: packageName,
  ).openPreferences('counters');
  var count = (prefs.getInt('launchCount') ?? 0) + 1;
  prefs.setInt('launchCount', count);
  await prefs.close();
  return count;
}

/// Async API: every call is awaited (same shape on Flutter).
Future<String> readTheme() async {
  var prefs = await dockGetPrefsAsyncFactory(
    packageName: packageName,
  ).openPreferences('settings');
  try {
    return await prefs.getString('theme') ?? 'light';
  } finally {
    await prefs.close();
  }
}
```

### sdb database with a schema

```dart
import 'package:tekartik_app_dock/sdb.dart';

const packageName = 'com.example.my_app';
final noteStore = SdbStoreRef<int, SdbModel>('note');

Future<void> main() async {
  var factory = dockGetSdbFactory(packageName: packageName);
  var db = await factory.openDatabase(
    'notes.db',
    options: SdbOpenDatabaseOptions(
      version: 1,
      schema: SdbDatabaseSchema(
        stores: [noteStore.schema(autoIncrement: true)],
      ),
    ),
  );
  var key = await noteStore.add(db, {'title': 'first'});
  print((await noteStore.record(key).get(db))?.value); // {title: first}
  await db.close();
}
```

### Test running on vm and chrome

```dart
import 'package:tekartik_app_dock/sembast.dart';
import 'package:test/test.dart';

// dart_test.yaml:
//   platforms:
//     - vm
//     - chrome
const testPackageName = 'com.example.my_app_test';

void main() {
  test('sembast round trip', () async {
    var factory = dockGetSembastDatabaseFactory(packageName: testPackageName);
    await factory.deleteDatabase('test.db');
    var db = await factory.openDatabase('test.db');
    var store = StoreRef<String, Object>.main();
    await store.record('key').put(db, 'value');
    expect(await store.record('key').get(db), 'value');
    await db.close();
  });
}
```
