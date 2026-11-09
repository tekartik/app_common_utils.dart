# tekartik_app_cv_sdb

Typed records for sdb, the simple IndexedDB shaped database of
[idb_shim](https://pub.dev/packages/idb_shim): a record is a
[cv](https://pub.dev/packages/cv) model (`CvField`s, no code generation)
that knows its key, a store is typed by its record class. The same code runs
on IndexedDB in the browser, on files on the VM, on SQLite in Flutter and in
memory in tests.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_cv_sdb:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_cv_sdb
```

One import (it re-exports `package:cv/cv.dart` and the sdb API of
`package:idb_shim/sdb/sdb.dart`):

```dart
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

class DbNote extends ScvIntRecordBase {
  final title = CvField<String>('title');

  @override
  CvFields get fields => [title];
}

final noteStore = scvIntStoreFactory.store<DbNote>('note');

Future<void> main() async {
  cvAddConstructors([DbNote.new]); // once, before any read
  var db = await newSdbFactoryMemory().openDatabase(
    'notes.db',
    options: SdbOpenDatabaseOptions(
      version: 1,
      schema: SdbDatabaseSchema(stores: [noteStore.schema(autoIncrement: true)]),
    ),
  );
  var note = await noteStore.add(db, DbNote()..title.v = 'Groceries');
  print(note.id); // 1, the generated key
  print((await noteStore.record(note.id).get(db))?.title.v); // Groceries
  await db.close();
}
```

See [example/main.dart](example/main.dart) (index, update, transaction).

## Platforms

Pick the factory where the app starts (all from the import above, except
SQLite):

| Platform | Factory |
|---|---|
| Browser, Flutter web (IndexedDB) | `sdbFactoryWeb` |
| Flutter Android, iOS, macOS, Windows, Linux (SQLite) | `sdbFactoryFromSqflite(databaseFactory)` from [idb_sqflite](https://pub.dev/packages/idb_sqflite) (`package:idb_sqflite/sdb_sqflite.dart`) |
| Dart VM (sembast files, one process) | `sdbFactoryIo` |
| Tests, any platform (memory) | `newSdbFactoryMemory()` |

## What to use

* Records: extend `ScvIntRecordBase` (int key) or `ScvStringRecordBase`,
  register them with `cvAddConstructors`.
* Stores: `scvIntStoreFactory.store<DbNote>('note')`,
  `scvStringStoreFactory.store<V>(name)`; `store.schema(...)` in the
  `SdbDatabaseSchema`.
* Records by key: `store.record(key)`: `get`, `put`, `add`, `delete`,
  `exists`, `onRecord`; or on a record with an id: `record.put(db)`,
  `add`, `update`, `delete`.
* Queries: `store.findRecords(db, boundaries:, filter:, limit:, ...)`,
  `findRecord`, `count`, `streamRecords`, `onRecords` (a stream of the
  results).
* Indexes: `store.index<I>(name)`, `index2`, `index3`, `index.schema(keyPath:)`,
  `index.findRecords`, `index.record(key).getObject(db)`.
* Transactions: every method takes a database or a transaction
  (`SdbClient`): `store.inTransaction(db, SdbTransactionMode.readWrite, (txn)
  async {...})`, `db.inScvStoresTransaction([...], mode, ...)`.
* Schema upgrade tests (VM): `ScvSchemaUpgradeValidator` from
  `package:tekartik_app_cv_sdb/test/scv_schema_upgrade_validator.dart`.

## Common pitfalls

* Reads and writes before `cvAddConstructors([DbNote.new])` throw
  `Missing builder for 'DbNote'`: records are built (and cloned) by cv.
* Stores and indexes are only created when the `version` increases: bump it
  with each schema change.
* Do not declare a Dart field named `id`, it hides the record key `id`:
  `final recId = CvField<int>('id');` with `store.schema(keyPath:
  SdbKeyPath.single('id'))` stores the key in the `id` field.
* In a transaction, pass `txn` (not `db`) to every call and do not await
  anything else (timer, network): an IndexedDB transaction commits as soon
  as it has nothing pending.
* `store.add` returns a new record carrying the id, the argument is
  unchanged.
* `List<ScvRecord>.put/delete` use one transaction on the store of the first
  record (one store per list). `Iterable<ScvRecordRef>.delete(db)` is one
  transaction per record (not atomic), give it a transaction.
* Index queries (`index.findRecords`, `findRecordKeys`, `onIndexRecords`,
  `onObjects`) return read-only lists: copy them (`toList()`) before
  sorting. The store queries return regular lists.
* A failed write (a duplicate on a unique index, ...) throws the error of
  the write, a `DatabaseError` (an `Error`, not an `Exception`, since
  idb_shim 2.11.3): catch it with `catch (e)`, or `on DatabaseError` with
  `import 'package:idb_shim/idb.dart' show DatabaseError;`.

## Agent skills

[skills/](skills/): `tekartik-app-cv-sdb-records` (records, stores, queries,
transactions), `tekartik-app-cv-sdb-index`, `tekartik-app-cv-sdb-schema-upgrade`.
