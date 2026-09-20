---
name: tekartik-app-sembast-factory
description: >-
  Use when opening a sembast database in a cross platform Dart/Flutter app with
  tekartik_app_sembast: getDatabaseFactory(packageName:, rootPath:, autoInit:)
  which returns sembast_sqflite on io/desktop and sembast_web (IndexedDB) on the
  web, databaseFactoryMemory for unit tests, databaseFactorySqfliteFfi from
  package:tekartik_app_sembast/setup/sembast_sqflite_ffi.dart,
  sqfliteWindowsFfiInit, and the sembast API (Database, DatabaseFactory,
  StoreRef, RecordRef, stringMapStoreFactory, intMapStoreFactory, openDatabase,
  deleteDatabase) re-exported by package:tekartik_app_sembast/sembast.dart.
---

# Cross platform sembast factory (tekartik_app_sembast)

`tekartik_app_sembast` answers one question: which `DatabaseFactory` should this
app use? It picks `sembast_sqflite` (over `sqflite`/`sqflite_common_ffi`) on the
Dart VM, Flutter mobile and desktop, and `sembast_web` (IndexedDB) on the web,
and re-exports the whole sembast API so a single import is enough.

## Guidelines

* Not on pub.dev, depend on it through git:
  ```yaml
  dependencies:
    tekartik_app_sembast:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_sembast
      version: '>=0.1.0'
  ```
* `import 'package:tekartik_app_sembast/sembast.dart';` gives
  `getDatabaseFactory(...)`, `databaseFactoryMemory` and everything of
  `package:sembast/sembast.dart` (`Database`, `DatabaseFactory`, `StoreRef`,
  `RecordRef`, `RecordSnapshot`, `Filter`, `Finder`, `Transaction`,
  `stringMapStoreFactory`, `intMapStoreFactory`, `StoreRef.main()`...). Do not
  import `sembast_io.dart`, `sembast_web.dart` or `sembast_sqflite.dart`
  directly, that defeats the platform selection.
* `getDatabaseFactory({String? packageName, String? rootPath, bool autoInit =
  true})`:
  * web: both paths are ignored, the factory is `databaseFactoryWeb`
    (IndexedDB), the database name is the IndexedDB name;
  * Android/iOS and any platform where the sqflite plugin is registered: the
    plugin factory and its default databases directory;
  * Linux/Windows/macOS: pass `packageName: 'com.example.myapp'` to store the
    databases under the user application data directory
    (`<appData>/<packageName>/databases`), or `rootPath: '.dart_tool/myapp'`
    to choose the directory yourself. Relative database names are resolved
    below it, absolute paths are used as is. With neither, the process
    current directory is used.
  * `autoInit` (default true) calls `sqfliteWindowsFfiInit()` for you on io;
    pass `autoInit: false` only when you initialize sqflite ffi yourself.
* Call `getDatabaseFactory(...)` once and keep the factory (and the opened
  `Database`) for the whole app lifetime: `var db = await
  factory.openDatabase('my_app.db');`. Sembast databases are cached per path,
  reopening is cheap but closing/reopening around each write is an
  anti-pattern. Do not `close()` in a Flutter app.
* Unit tests: use `databaseFactoryMemory` (this package's getter, backed by
  sembast's `databaseFactoryMemoryFs`, so paths and `deleteDatabase` behave
  like a file system) or `newDatabaseFactoryMemory()` from
  `package:sembast/sembast_memory.dart` for a factory isolated per test. Start
  each test with `await factory.deleteDatabase(path)`.
* On the Dart VM (a `dart test` run, a CLI tool), the io factory uses
  `sqflite_common_ffi`; `sqfliteWindowsFfiInit()` (from
  `package:tekartik_app_sqflite/sqflite.dart`) is what makes it work on
  Windows. The package tests call it explicitly before `getDatabaseFactory()`.
* For a VM/desktop only program that never runs on the web, importing
  `package:tekartik_app_sembast/setup/sembast_sqflite_ffi.dart` and using the
  ready made `databaseFactorySqfliteFfi` is simpler (it also re-exports
  `package:sembast/sembast.dart`).
* Store/record API is plain sembast: declare `StoreRef` objects globally
  (`intMapStoreFactory.store('book')`, `stringMapStoreFactory.store('config')`,
  `StoreRef<String, String>.main()`), and read/write with
  `store.record(key).put(db, value)` / `.get(db)` / `store.find(db, finder:
  ...)`. Group writes in `db.transaction((txn) async {...})`.
* Anti-patterns: opening the database in every function; passing a
  `packageName` on the web and expecting a path; forgetting `deleteDatabase`
  between tests; using `dart:io` to build the database path on the web;
  depending on `sqflite` directly instead of `tekartik_app_sqflite`.
* A unique secondary index on a store is available in the same package, see
  [tekartik-app-sembast-unique-index](../tekartik-app-sembast-unique-index/SKILL.md).

## Examples

### Open once, use everywhere

```dart
import 'package:tekartik_app_sembast/sembast.dart';

/// Declare the stores globally (typed key/value).
var settingStore = StoreRef<String, String>.main();
var bookStore = intMapStoreFactory.store('book');

Database? _db;

Future<Database> getDatabase() async {
  return _db ??= await getDatabaseFactory(
    // Only used on Linux/Windows/macOS.
    packageName: 'com.example.myapp',
  ).openDatabase('my_app.db');
}

Future<void> main() async {
  var db = await getDatabase();

  await settingStore.record('theme').put(db, 'dark');
  print(await settingStore.record('theme').get(db));

  var key = await bookStore.add(db, {'code': 'BOOK001', 'title': 'A book'});
  var snapshot = await bookStore.record(key).getSnapshot(db);
  print(snapshot!.value['title']);

  // Group related writes.
  await db.transaction((txn) async {
    await bookStore.record(key).update(txn, {'title': 'Another title'});
    await settingStore.record('lastBook').put(txn, '$key');
  });

  var books = await bookStore.find(
    db,
    finder: Finder(filter: Filter.matches('title', 'Another.*')),
  );
  print(books.length);

  // Not needed in a Flutter app: keep it open.
  await db.close();
}
```

### A local directory instead of the application data folder

```dart
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sqflite/sqflite.dart' show sqfliteWindowsFfiInit;

Future<void> main() async {
  // Needed on Windows when autoInit is disabled; harmless elsewhere.
  sqfliteWindowsFfiInit();

  // Databases are created below this directory (io only, ignored on the web).
  var factory = getDatabaseFactory(
    rootPath: '.dart_tool/my_app/db',
    autoInit: false,
  );

  await factory.deleteDatabase('test.db');
  var db = await factory.openDatabase('test.db');
  var store = StoreRef<String, String>.main();
  await store.record('k').put(db, 'v');
  print(await store.record('k').get(db));
  await db.close();
}
```

### Unit test on the in memory factory

```dart
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:test/test.dart';

void main() {
  group('book store', () {
    var store = intMapStoreFactory.store('book');
    late Database db;

    setUp(() async {
      // One isolated factory per test, nothing on disk.
      var factory = newDatabaseFactoryMemory();
      db = await factory.openDatabase('test.db');
    });
    tearDown(() async {
      await db.close();
    });

    test('add/get', () async {
      var key = await store.add(db, {'code': 'BOOK001'});
      expect((await store.record(key).get(db))!['code'], 'BOOK001');
      expect(await store.count(db), 1);
    });
  });

  test('shared memory factory', () async {
    // databaseFactoryMemory comes from tekartik_app_sembast (memory fs).
    await databaseFactoryMemory.deleteDatabase('other.db');
    var db = await databaseFactoryMemory.openDatabase('other.db');
    await db.close();
  });
}
```

### Dart VM / desktop only program

```dart
// No web support needed: use the sqflite ffi factory directly.
import 'package:tekartik_app_sembast/setup/sembast_sqflite_ffi.dart';

Future<void> main() async {
  var db = await databaseFactorySqfliteFfi.openDatabase(
    '.dart_tool/my_tool/tool.db',
  );
  var store = StoreRef<String, Object>.main();
  await store.record('count').put(db, 1);
  print(await store.record('count').get(db));
  await db.close();
}
```
