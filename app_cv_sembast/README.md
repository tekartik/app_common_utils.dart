# tekartik_app_cv_sembast

Typed records for [sembast](https://pub.dev/packages/sembast): a record is a
[cv](https://pub.dev/packages/cv) model (`CvField`s, no code generation)
that knows its sembast key, a store is typed by its record class, queries
and change streams return records.

For new local database code, prefer
[tekartik_app_cv_sdb](../app_cv_sdb) (the same idea on idb_shim's sdb,
IndexedDB in the browser, SQLite in Flutter).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_cv_sembast:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_cv_sembast
```

One import (it re-exports `package:cv/cv.dart` and
`package:sembast/sembast.dart`), plus the factory you open the database
with:

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

class DbNote extends DbIntRecordBase {
  final title = CvField<String>('title');

  @override
  CvFields get fields => [title];
}

final noteStore = dbIntStoreFactory.store<DbNote>('note');

Future<void> main() async {
  cvAddConstructors([DbNote.new]); // once, before any read
  var db = await newDatabaseFactoryMemory().openDatabase('notes.db');
  var note = await noteStore.add(db, DbNote()..title.v = 'Groceries');
  print(note.id); // 1, the generated key
  print((await noteStore.record(note.id).get(db))?.title.v); // Groceries
  await db.close();
}
```

See [example/main.dart](example/main.dart) (update, finder, change stream,
json).

## Platforms

As sembast: `databaseFactoryIo` (`package:sembast/sembast_io.dart`) on the
Dart VM and in Flutter mobile/desktop (with a path from path_provider),
`databaseFactoryWeb` ([sembast_web](https://pub.dev/packages/sembast_web))
in the browser, `newDatabaseFactoryMemory()` in tests.

## What to use

* Records: extend `DbIntRecordBase` (int key) or `DbStringRecordBase`,
  register them with `cvAddConstructors`. Field types are sembast values
  (`int`, `double`, `bool`, `String`, lists, maps, `Timestamp`, `Blob`).
* Stores: `dbIntStoreFactory.store<DbNote>('note')`,
  `dbStringStoreFactory.store<V>(name)`.
* By key: `store.record(key)`: `get`, `put`, `add`, `delete`, `exists`,
  `onRecord`, `cv()` (an empty record bound to the key); on a record with an
  id: `record.put(db)`, `add`, `update`, `delete`.
* Queries: `store.find(db, finder: Finder(...))`, `findFirst`,
  `store.query(finder: ...)`: `getRecords`, `count`, `getKeys`, `delete`,
  `onRecords`, `onCount` (and their `*Sync` variants).
* Transactions: every method takes a `DatabaseClient`;
  `client.transaction((txn) async {...})` opens one on a database and reuses
  the current one in a transaction.
* JSON: `record.toJsonEncodable()`, `dbToJson()`, `dbToJsonPretty()`.

## Common pitfalls

* Reads before `cvAddConstructors([DbNote.new])` throw
  `Missing builder for 'DbNote'`.
* `find`, `getRecords` and `records(keys).get` return read-only lists: copy
  them (`toList()`) before sorting, or sort in the `Finder`.
* Streams need the `Database`, not a transaction; cancel the subscriptions.
* Use sembast 3.10.1 or later: in a transaction that changed records, older
  versions returned wrong results for a `Finder` with a `limit` or an
  `offset` and no sort order, and a wrong count for
  `store.delete(client, finder: ...)` and for `List<DbRecord>.delete` (a
  record deleted twice).
* Records compare by content (cv `==`), not by key.

## Agent skills

[skills/](skills/): `tekartik-app-cv-sembast-records` (records, stores,
transactions), `tekartik-app-cv-sembast-query` (finders, streams, json).
