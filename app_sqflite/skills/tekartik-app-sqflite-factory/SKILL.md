---
name: tekartik-app-sqflite-factory
description: >-
  Use when opening a sqflite/sqlite database from a cross platform Dart or
  Flutter app with tekartik_app_sqflite: the databaseFactory getter,
  getDatabaseFactory(packageName:, rootPath:, autoInit:) which stores desktop
  databases under the user app data directory, and sqfliteWindowsFfiInit(),
  from package:tekartik_app_sqflite/sqflite.dart, which also re-exports the
  sqflite_common API (Database, DatabaseFactory, OpenDatabaseOptions,
  Transaction, Batch, ConflictAlgorithm, DatabaseException,
  inMemoryDatabasePath, query/insert/update/delete/rawQuery).
---

# Cross platform sqflite factory (tekartik_app_sqflite)

`tekartik_app_sqflite` answers one question: which sqflite `DatabaseFactory`
should this app use? On the Dart VM and desktop it uses `sqflite_common_ffi`
(or the registered `sqflite` Flutter plugin when there is one), on the web
`sqflite_common_ffi_web`, and it re-exports the whole `sqflite_common` API so a
single import is enough.

## Guidelines

* Not on pub.dev, depend on it through git (the package lives in the
  `app_sqflite/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_sqflite:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_sqflite
      version: '>=0.2.0'
  ```
* Import `package:tekartik_app_sqflite/sqflite.dart` only: it re-exports
  `package:sqflite_common/sqlite_api.dart`, so `Database`, `DatabaseFactory`,
  `OpenDatabaseOptions`, `Transaction`, `Batch`, `ConflictAlgorithm`,
  `DatabaseException`, `QueryCursor` and `inMemoryDatabasePath` come with it.
  Never import `sqflite_common_ffi` / `sqflite_common_ffi_web` directly in app
  code.
* Three top level members, nothing else:
  * `DatabaseFactory get databaseFactory` - the default factory. On io it is
    the `sqflite` plugin factory when it is registered (Flutter
    Android/iOS/macOS), else `databaseFactoryFfi`; on the web it is
    `databaseFactoryFfiWeb`.
  * `DatabaseFactory getDatabaseFactory({String? packageName, String? rootPath,
    bool autoInit = true})` - same factory, with a per app databases location.
  * `void sqfliteWindowsFfiInit()` - initializes `sqflite_common_ffi` (needed
    on Windows during development to find `sqlite3.dll`); it is a no-op-ish
    call on the other io platforms and throws `UnimplementedError` on the web.
* `packageName`/`rootPath` only change anything on **desktop** (Linux, Windows,
  macOS): the returned factory resolves relative paths under
  `<userAppDataPath>/<packageName>/databases` (or under `rootPath`), creates
  the parent directory on open/write, and returns that path from
  `getDatabasesPath()`. On mobile and the web both arguments are ignored.
  Pass one of them (typically a reverse DNS `packageName`) instead of relying
  on the default desktop databases path.
* `autoInit` (default `true`) makes `getDatabaseFactory()` call
  `sqfliteWindowsFfiInit()` for you. Keep it, or call
  `sqfliteWindowsFfiInit()` once at startup (that is what a plain
  `databaseFactory` user must do on Windows).
* An absolute path is always used as-is; on mobile the plugin resolves a
  relative path under its own databases directory. For a real Flutter app,
  prefer `path_provider` + `package:path`'s `join` to build an absolute path,
  as the README says, because `getDatabasesPath()` is only meaningful on
  Android/iOS.
* Web: `databaseFactoryFfiWeb` needs its assets in `web/` - run
  `dart run sqflite_common_ffi_web:setup` once (it copies `sqlite3.wasm` and
  `sqflite_sw.js`). Without them the database fails to open at runtime.
  On a platform with neither `dart:io` nor `dart:js_interop` the stub
  implementation throws `UnimplementedError`.
* Open with `factory.openDatabase(path, options: OpenDatabaseOptions(version:
  1, onCreate: ..., onUpgrade: ...))` - this factory API takes an `options:`
  object, not the top level `openDatabase(path, version:, onCreate:)` of the
  `sqflite` plugin. Always `await db.close()` when done.
* Tests: `inMemoryDatabasePath` (`:memory:`) with `databaseFactory` gives a
  fast, isolated database; `singleInstance` is forced to false for it.
  Prefer it over a temporary file. On Linux/Windows the test process needs the
  sqlite3 native library (`libsqlite3` / `sqlite3.dll`); call
  `sqfliteWindowsFfiInit()` at the top of `main()`.
* Only need a document/key-value store rather than SQL? `tekartik_app_sembast`
  layers sembast on top of the same factories.
* Anti-patterns: importing `sqflite_common_ffi` in shared code; calling
  `getDatabasesPath()` on desktop and expecting a per app directory without
  passing `packageName`; opening the same relative path from factories built
  with different `packageName`s; forgetting `sqfliteWindowsFfiInit()` on
  Windows; using the database object instead of the `txn` inside
  `transaction()` (that deadlocks).

## Examples

### Open a database with the default factory

```dart
import 'package:tekartik_app_sqflite/sqflite.dart';

Future<Database> openPrefDatabase(String path) async {
  return databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE Pref (
  id TEXT PRIMARY KEY,
  value INTEGER NOT NULL
)
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // await db.execute('ALTER TABLE Pref ADD COLUMN label TEXT');
        }
      },
    ),
  );
}

Future<void> main() async {
  // On Windows, during development, make sure sqlite3.dll is found.
  sqfliteWindowsFfiInit();

  var db = await openPrefDatabase('pref.db');
  await db.insert('Pref', <String, Object?>{'id': 'counter', 'value': 1},
      conflictAlgorithm: ConflictAlgorithm.replace);
  print(await db.query('Pref', where: 'id = ?', whereArgs: ['counter']));
  await db.close();
}
```

### Per application databases location (desktop)

```dart
import 'package:tekartik_app_sqflite/sqflite.dart';

Future<void> main() async {
  // On Linux/Windows/macOS: <userAppDataPath>/com.example.myapp/databases.
  // On mobile and web packageName is ignored. autoInit defaults to true and
  // takes care of sqfliteWindowsFfiInit().
  var factory = getDatabaseFactory(packageName: 'com.example.myapp');
  print(await factory.getDatabasesPath());

  // A relative path is resolved there, and the directory is created.
  var db = await factory.openDatabase(
    'data.db',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)',
        );
      },
    ),
  );
  await db.close();

  // Or an explicit root directory (tests, portable app, custom location).
  var rootFactory = getDatabaseFactory(rootPath: '.dart_tool/my_app/databases');
  print(await rootFactory.databaseExists('data.db'));
  await rootFactory.deleteDatabase('data.db');
}
```

### In memory database in a test

```dart
import 'package:tekartik_app_sqflite/sqflite.dart';
import 'package:test/test.dart';

void main() {
  sqfliteWindowsFfiInit();

  late Database db;
  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Item (id INTEGER PRIMARY KEY, name TEXT)',
          );
        },
      ),
    );
  });
  tearDown(() async => db.close());

  test('insert/query in a transaction', () async {
    await db.transaction((txn) async {
      // Use txn, never db, inside a transaction.
      await txn.insert('Item', <String, Object?>{'name': 'first'});
      await txn.insert('Item', <String, Object?>{'name': 'second'});
    });
    expect(await db.query('Item', orderBy: 'id'), [
      {'id': 1, 'name': 'first'},
      {'id': 2, 'name': 'second'},
    ]);
    expect(await db.getVersion(), 1);
  });

  test('batch', () async {
    var batch = db.batch();
    batch.insert('Item', <String, Object?>{'name': 'a'});
    batch.rawUpdate('UPDATE Item SET name = ? WHERE name = ?', ['b', 'a']);
    await batch.commit();
    expect((await db.query('Item')).first['name'], 'b');
  });
}
```
