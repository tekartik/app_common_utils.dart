# tekartik_app_sqflite

One import to get a sqflite `DatabaseFactory` in a Dart or Flutter app, on
every platform: `sqflite_common_ffi` on the Dart VM and desktop (or the
`sqflite` plugin factory when a Flutter app has the plugin), and
`sqflite_common_ffi_web` on the web. It re-exports the `sqflite_common` API
(`Database`, `OpenDatabaseOptions`, `Transaction`, `Batch`,
`inMemoryDatabasePath`...) and, on desktop, can keep the databases of an app
in its own folder.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_sqflite:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_sqflite
```

```dart
import 'package:tekartik_app_sqflite/sqflite.dart';

Future<void> main() async {
  var db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Note (id INTEGER PRIMARY KEY, title TEXT)',
        );
      },
    ),
  );
  await db.insert('Note', <String, Object?>{'title': 'hello'});
  print(await db.query('Note')); // [{id: 1, title: hello}]
  await db.close();
}
```

Run it with `dart run` or `dart test`: they run the `sqlite3` build hooks,
which bundle SQLite (nothing to install). See
[example/main.dart](example/main.dart) for a database file per app.

## Platforms

| Platform | `databaseFactory` | Setup |
|---|---|---|
| Dart VM, Linux, Windows, macOS | `databaseFactoryFfi` | none (SQLite bundled by the build hooks) |
| Flutter with the `sqflite` plugin (Android, iOS, macOS) | the plugin factory, set by the plugin at startup | add `sqflite` to the app |
| Web (dart2js, dart2wasm) | `databaseFactoryFfiWeb` | `dart run sqflite_common_ffi_web:setup` once: it writes `web/sqlite3.wasm` and `web/sqflite_sw.js` |

## What to use

* `databaseFactory`: the factory of the platform (table above).
* `getDatabaseFactory(packageName: 'com.example.app')`: on Linux, Windows
  and macOS, relative paths are opened in
  `<userAppDataPath>/com.example.app/databases` (created on open), which
  `getDatabasesPath()` returns. `rootPath: '/an/absolute/folder'` uses that
  folder instead. Both are ignored on mobile and on the web, which return
  `databaseFactory`.
* `sqfliteWindowsFfiInit()`: opens SQLite once in the main isolate on
  Windows (no-op on the other io platforms). `getDatabaseFactory` calls it
  (`autoInit: true`); call it yourself before using `databaseFactory` on
  Windows.
* The whole `package:sqflite_common/sqlite_api.dart` API, from the same
  import.

## Common pitfalls

* Give an absolute `rootPath`: a relative one is resolved a second time by
  the ffi factory, so the files land in
  `.dart_tool/sqflite_common_ffi/databases/<rootPath>`, not in the folder
  `getDatabasesPath()` returns.
* The factory API takes `options: OpenDatabaseOptions(...)`, not the
  `openDatabase(path, version:, onCreate:)` top level function of the
  `sqflite` plugin.
* `sqfliteWindowsFfiInit()` throws `UnimplementedError` on the web: guard it
  in code shared with a web app.
* `inMemoryDatabasePath` (`:memory:`) and `setDatabasesPath` work with a
  `packageName`/`rootPath` factory since 2026-11-09 (before, `:memory:`
  became a file and `setDatabasesPath` threw a `LateInitializationError`).
* On the web there is no file system: a path is only a name, stored in
  IndexedDB.
* Use the `txn` given by `transaction()` inside it, never the `db`: that
  deadlocks.

## Agent skills

[skills/tekartik-app-sqflite-factory](skills/tekartik-app-sqflite-factory/SKILL.md).
