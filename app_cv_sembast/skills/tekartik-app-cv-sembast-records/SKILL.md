---
name: tekartik-app-cv-sembast-records
description: >-
  Use when storing package:cv models in a sembast database with
  tekartik_app_cv_sembast: define DbIntRecordBase / DbStringRecordBase
  records (CvField fields, cvAddConstructors), declare stores with
  dbIntStoreFactory.store<T>() / dbStringStoreFactory.store<T>() (DbStoreRef,
  DbIntStoreRef, DbStringStoreRef), get record refs with store.record(key)
  (DbRecordRef: cv, get, getSync, exists, put, add, delete, onRecord), write
  with record.put / add / update / delete, store.add, list put / delete,
  DbRecordsRef, read ids (id, idOrNull, hasId, ref, rawRef), dbClone, convert
  a RecordSnapshot with cv<T>(), run helpers on a DatabaseClient with
  client.transaction, Timestamp and Blob fields. Queries, change streams and
  json export are in the tekartik-app-cv-sembast-query skill.
---

# cv records in sembast (tekartik_app_cv_sembast)

`tekartik_app_cv_sembast` binds `package:cv` models (typed `CvField`s, map
conversion) to `package:sembast` stores: a `DbRecord` is a `CvModel` that
remembers its sembast `RecordRef`, a `DbStoreRef<K, V>` is a typed view on a
`StoreRef<K, Map<String, Object?>>`. It runs wherever sembast runs (VM,
Flutter, web with `sembast_web`).

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_cv_sembast:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_cv_sembast
    cv: ^1.1.6
    sembast: ^3.8.3
  ```
* One import: `package:tekartik_app_cv_sembast/app_cv_sembast.dart`
  re-exports `package:cv/cv.dart` and `package:sembast/sembast.dart`. Add
  `package:sembast/timestamp.dart` / `package:sembast/blob.dart` for those
  field types and `package:sembast/sembast_memory.dart` (or
  `sembast_io.dart`, `sembast_web`) to open a database.
* Define a record as a class extending `DbIntRecordBase` (int keys) or
  `DbStringRecordBase` (string keys) with `final` `CvField`s and
  `List<CvField> get fields`. Register every record class once with
  `cvAddConstructors([DbNote.new, ...])` (app start, or `setUpAll` in
  tests) before reading: `get`, `find` and streams build instances through
  `cvBuildModel`.
* Declare stores as top level finals:
  `final noteStore = dbIntStoreFactory.store<DbNote>('note');` is a
  `DbIntStoreRef<DbNote>` (`DbStoreRef<int, DbNote>`),
  `dbStringStoreFactory.store<DbUser>('user')` a `DbStringStoreRef<DbUser>`;
  no name means the main store. Stores are equal by name; `rawRef` is the
  sembast `StoreRef`. `cast<RK, RV>()` / `castV<RV>()` re-type a store
  (read the same store as another model).
* `store.record(key)` is a `DbRecordRef<K, V>` (`key`, `store`, `rawRef`,
  equal by store and key). `ref.cv()` creates an empty `V` bound to the
  ref, the normal way to build a record for writing:
  `await (noteStore.record(1).cv()..title.v = 'x').put(db);`
* Record ref reads: `get(client)` / `getSync(client)` return `V?` with the
  ref set, `exists(client)` / `existsSync(client)`. Record ref writes:
  `put(client, value, {merge})` upserts and returns a new `V` holding the
  stored content and the ref; `add(client, value)` inserts only when
  absent and returns the key or `null` (it does not touch `value`);
  `delete(client)`.
* Record writes (extension on `DbRecord`, the record must have a ref):
  `put(client, {merge})` upserts and refreshes the fields from the stored
  map; `add(client)` returns `false` when the key exists; `update(client)`
  merges into an existing record and returns `false` when missing (never
  creates); `delete(client)` returns whether something was deleted.
  `store.add(client, record)` inserts with a generated key, sets
  `record.rawRef` on that same instance and returns it.
* Ids: `hasId`, `id` (throws without a ref), `idOrNull`, `ref` (typed
  `DbRecordRef`), `refOrNull`, `rawRef` (sembast `RecordRef`); setters
  `id = key` (same store), `ref = store.record(key)`, `refOrNull = null`.
  A `DbNote()` built with its constructor has no id until you set one or
  `store.add` it. `record.dbClone()` copies fields and ref (`clone()` from
  cv drops the ref).
* Lists: `store.records([k1, k2])` is a `DbRecordsRef` (`get(client)`
  gives `List<V?>`, `getSync`, `delete(client)`, `refs`, `keys`, `[i]`,
  `cv()`); `List<DbRecord<K>>.put(client, {merge})` and `.delete(client)`
  run a single transaction; `.ids`; `List<DbIntRecord>.toMap()` /
  `List<DbStringRecord>.toMap()` index records by id.
* Raw sembast interop: `snapshot.cv<DbNote>()`, `snapshots.cv<DbNote>()`,
  `List<RecordSnapshot?>.cvOrNull<T>()` and
  `Stream<List<RecordSnapshot?>>.cvOrNull<T>()` convert what sembast
  `find`, `getSnapshots` and `onSnapshots` return.
* Every data method takes a `DatabaseClient` (`Database` or
  `Transaction`); inside `db.transaction((txn) async {...})` use only
  `txn`. Write helpers against `DatabaseClient` and group their writes
  with `client.transaction((txn) async {...})`
  (`DbDatabaseClientSembastExt`): it opens a transaction on a `Database`
  and reuses the current one on a `Transaction`, so helpers compose
  without nesting.
* Field types must be sembast values: `CvField<int|double|bool|String>`,
  `CvListField<T>`, `CvModelField<M>`, `CvField<Model>`,
  `CvField<Timestamp>`, `CvField<Blob>`; never `DateTime`, `Uint8List` or
  enums (store `.name`). `cvSembastFillOptions1` (`record.fillModel(...)`)
  fills such models with deterministic values in tests.
* Records compare by content (`==` from cv), not by key: compare `rawRef`
  when identity matters.
* Compat aliases (`CvStoreRef`, `CvRecordRef`, `CvRecordsRef`,
  `CvQueryRef`, `cvIntStoreFactory`, `cvStringStoreFactory`) exist for old
  code and `cvIntRecordFactory` / `cvStringRecordFactory` are deprecated:
  use the `Db*` names.
* Tests: `newDatabaseFactoryMemory().openDatabase('test')` from
  `sembast_memory.dart`, one database per test, `db.close()` in
  `tearDown`.

## Examples

### Model, store and CRUD

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/timestamp.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

class DbNote extends DbIntRecordBase {
  final title = CvField<String>('title');
  final content = CvField<String>('content');
  final createdAt = CvField<Timestamp>('createdAt');

  @override
  List<CvField> get fields => [title, content, createdAt];
}

final noteStore = dbIntStoreFactory.store<DbNote>('note');

Future<void> main() async {
  cvAddConstructors([DbNote.new]);
  var db = await newDatabaseFactoryMemory().openDatabase('notes.db');

  // Insert with a generated key: the instance gets its id.
  var note = await noteStore.add(
    db,
    DbNote()
      ..title.v = 'First'
      ..createdAt.v = Timestamp.now(),
  );
  print(note.id); // 1

  // Upsert on a chosen key.
  await (noteStore.record(10).cv()..title.v = 'Tenth').put(db);

  // Read.
  var read = await noteStore.record(10).get(db);
  print('${read?.id} ${read?.title.v}'); // 10 Tenth

  // Modify and save back.
  read!.content.v = 'body';
  await read.put(db);

  // Merge some fields only.
  await noteStore.record(10).put(db, DbNote()..title.v = 'Renamed', merge: true);
  print((await noteStore.record(10).get(db))?.content.v); // body

  // Delete.
  print(await note.delete(db)); // true
  print(await noteStore.record(1).exists(db)); // false
  await db.close();
}
```

### Helpers taking a DatabaseClient

```dart
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

class DbCounter extends DbStringRecordBase {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

final counterStore = dbStringStoreFactory.store<DbCounter>('counter');

/// Works with a Database or a Transaction.
Future<int> increment(DatabaseClient client, String name) {
  return client.transaction((txn) async {
    var ref = counterStore.record(name);
    var counter = await ref.get(txn) ?? ref.cv();
    counter.value.v = (counter.value.v ?? 0) + 1;
    await counter.put(txn);
    return counter.value.v!;
  });
}

/// Two increments in one atomic transaction.
Future<void> incrementBoth(Database db) => db.transaction((txn) async {
  await increment(txn, 'a');
  await increment(txn, 'b');
});
```

### Batches with keyed records and DbRecordsRef

```dart
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

class DbTag extends DbStringRecordBase {
  final label = CvField<String>('label');
  final count = CvField<int>('count');

  @override
  List<CvField> get fields => [label, count];
}

final tagStore = dbStringStoreFactory.store<DbTag>('tag');

Future<void> importTags(Database db, Map<String, String> labels) async {
  // Records bound to their keys, written in one transaction.
  var tags = [
    for (var entry in labels.entries)
      tagStore.record(entry.key).cv()
        ..label.v = entry.value
        ..count.v = 0,
  ];
  await tags.put(db);
  print(tags.ids); // the keys

  // Read a batch back, missing ones are null.
  var some = await tagStore.records(['dart', 'missing']).get(db);
  print(some.map((tag) => tag?.label.v).toList()); // [Dart, null]

  // Index by id.
  var byId = (await tagStore.find(db)).toMap();
  print(byId['dart']?.label.v); // Dart

  // Delete a batch, returns the number deleted.
  print(await tags.delete(db));
}
```
