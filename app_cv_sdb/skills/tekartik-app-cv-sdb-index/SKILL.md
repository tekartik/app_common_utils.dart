---
name: tekartik-app-cv-sdb-index
description: >-
  Use when declaring or querying sdb indexes over cv records with
  tekartik_app_cv_sdb: store.index<I>(name), index2<I1, I2>(name), index3
  (ScvIndex1Ref, ScvIndex2Ref, ScvIndex3Ref), index.schema(keyPath:, unique:)
  inside SdbDatabaseSchema or openStore.createIndex(index, keyPath), index
  queries findRecords / findRecord / findRecordKeys / findRecordKey /
  streamRecords / count / delete / onIndexRecords / onObjects, lowerBoundary
  / upperBoundary with SdbBoundaries, index.record(key) ScvIndexRecordRef
  (get, getKey, getObject, findRecords, findObjects, findObject,
  findRecordPrimaryKeys, count, delete, onIndexRecord, onObject,
  onIndexRecords, onObjects) and ScvIndexRecord / ScvIndexRecordKey (record,
  key, indexKey), composite (I1, I2) keys. Stores and records are in
  tekartik-app-cv-sdb-records.
---

# Indexes on cv records in sdb (tekartik_app_cv_sdb)

sdb indexes are IndexedDB indexes: a key path (one field or a list of
fields) over an object store, maintained by the database and queried by
index key or key range. `tekartik_app_cv_sdb` types them by the record
class of their store (`ScvIndex1Ref<K, V, I>`, `ScvIndex2Ref<K, V, I1, I2>`
whose keys are `(I1, I2)` records, `ScvIndex3Ref`) and returns `V` records
or `ScvIndexRecord` wrappers.

## Guidelines

* Import `package:tekartik_app_cv_sdb/app_cv_sdb.dart`; define the store
  as in `tekartik-app-cv-sdb-records`, then declare the index next to it:
  `final noteByTitle = noteStore.index<String>('title');`,
  `final memberByUserProject = memberStore.index2<int, String>('user_project');`,
  `store.index3<I1, I2, I3>(name)`. Index keys are `String`, `int`,
  `double`, `SdbTimestamp` or lists of them; a record whose indexed field
  is null (for composite indexes: any of them) is simply absent from the
  index.
* Create it in the schema: `noteStore.schema(indexes:
  [noteByTitle.schema(keyPath: 'title')])`; composite:
  `memberByUserProject.schema(keyPath: ['user_id', 'project_id'])`;
  `unique: true` makes a duplicate insert fail (`add` / `put` throws).
  Take key paths from a model instance (`DbNote().title.name`). Or
  imperatively in `onVersionChange`:
  `event.db.scvCreateStore(noteStore).createIndex(noteByTitle, 'title')`.
  Adding an index to an existing store needs a new database version.
* `index.name`, `index.store`, `index.rawRef` (the idb_shim `SdbIndexRef`).
* Index queries (any `SdbClient`): `findRecords(client, {boundaries,
  filter, offset, limit, descending, options})` returns
  `List<ScvIndexRecord>` ordered by index key then primary key; each has
  `.record` (the `V`, with its ref), `.key` (primary key) and `.indexKey`.
  `findRecord` (first or `null`), `findRecordKeys` / `findRecordKey`
  (`ScvIndexRecordKey`: `key` and `indexKey` only, no value read),
  `streamRecords(client, {options})`, `count(client, {boundaries})`,
  `delete(client, {boundaries, offset, limit, descending})`, and the
  streams `onIndexRecords(db, {options})` and `onObjects(db, {options})`
  (`Stream<List<V>>`).
* Boundaries: `SdbBoundaries.lower(index.lowerBoundary(v))`,
  `SdbBoundaries(index.lowerBoundary(a), index.upperBoundary(b))`,
  `SdbBoundaries.values(a, b)`, `SdbBoundaries.lowerValue(v)` /
  `.upperValue(v)`, `SdbBoundaries.key(v)` (exactly `v`). `lowerBoundary`
  includes its value by default, `upperBoundary` excludes it (`include:`
  to change). On a composite index pass every component:
  `index2.lowerBoundary(v1, v2)`.
* `index.record(indexKey)` (`index2.record(k1, k2)`, `index3.record(k1,
  k2, k3)`) is an `ScvIndexRecordRef` targeting every record whose index
  key equals it. `get(client)` gives the first `ScvIndexRecord?`,
  `getObject(client)` the first `V?`, `getKey(client)` its primary key;
  `findRecords`, `findObjects`, `findObject`,
  `findRecordPrimaryKeys(client, {options})` and `count(client,
  {options})` cover duplicates (non unique index); `delete(client,
  {options})` deletes every matching record; streams `onIndexRecord(db)`
  (`ScvIndexRecord?`), `onObject(db)` (`V?`), `onIndexRecords(db,
  {options})`, `onObjects(db, {options})`. `indexKey`, `index` and
  `store` describe the ref. `onRecord` / `onRecords` are deprecated
  aliases.
* Records read through an index carry their store ref: modify and
  `record.put(db)`, the index follows; delete with `record.delete(db)` or
  `store.record(indexRecord.key).delete(db)`.
* Composite index keys are Dart records ordered by position:
  `indexRecord.indexKey` is a `(I1, I2)` tuple.
* Streams need the `SdbDatabase`; `find*`, `count` and `delete` accept a
  transaction (`store.inTransaction`, `db.inScvStoresTransaction`).

## Examples

### Single field indexes: exact lookup and ranges

```dart
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

class DbNote extends ScvIntRecordBase {
  final title = CvField<String>('title');
  final updatedAt = CvField<SdbTimestamp>('updatedAt');

  @override
  List<CvField> get fields => [title, updatedAt];
}

final dbNoteModel = DbNote();
final noteStore = scvIntStoreFactory.store<DbNote>('note');
final noteByTitle = noteStore.index<String>('title');
final noteByUpdatedAt = noteStore.index<SdbTimestamp>('updated_at');

final noteSchema = SdbDatabaseSchema(
  stores: [
    noteStore.schema(
      autoIncrement: true,
      indexes: [
        noteByTitle.schema(keyPath: dbNoteModel.title.name, unique: true),
        noteByUpdatedAt.schema(keyPath: dbNoteModel.updatedAt.name),
      ],
    ),
  ],
);

Future<void> main() async {
  cvAddConstructors([DbNote.new]);
  var db = await newSdbFactoryMemory().openDatabase(
    'notes.db',
    options: SdbOpenDatabaseOptions(version: 1, schema: noteSchema),
  );
  for (var title in ['alpha', 'beta', 'gamma']) {
    await noteStore.add(
      db,
      DbNote()
        ..title.v = title
        ..updatedAt.v = SdbTimestamp.now(),
    );
  }

  // Exact lookup on a unique index.
  var beta = await noteByTitle.record('beta').getObject(db);
  print(beta?.id); // 2

  // Range: titles from 'b' (included) to 'g' (excluded), highest first.
  var some = await noteByTitle.findRecords(
    db,
    boundaries: SdbBoundaries(
      noteByTitle.lowerBoundary('b'),
      noteByTitle.upperBoundary('g'),
    ),
    descending: true,
  );
  print(some.map((r) => '${r.key}:${r.indexKey}').toList()); // [2:beta]

  // Most recently updated note.
  var latest = await noteByUpdatedAt.findRecord(db, descending: true);
  print(latest?.record.title.v); // gamma

  // Update through the record: the index follows.
  beta!.title.v = 'delta';
  await beta.put(db);
  print(await noteByTitle.record('beta').count(db)); // 0
  await db.close();
}
```

### Composite index as a unique business key

```dart
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

class DbMember extends ScvIntRecordBase {
  final userId = CvField<int>('user_id');
  final projectId = CvField<String>('project_id');
  final role = CvField<String>('role');

  @override
  List<CvField> get fields => [userId, projectId, role];
}

final dbMemberModel = DbMember();
final memberStore = scvIntStoreFactory.store<DbMember>('member');
final memberByUserProject = memberStore.index2<int, String>('user_project');

final memberSchema = SdbDatabaseSchema(
  stores: [
    memberStore.schema(
      autoIncrement: true,
      indexes: [
        memberByUserProject.schema(
          keyPath: [dbMemberModel.userId.name, dbMemberModel.projectId.name],
          unique: true,
        ),
      ],
    ),
  ],
);

/// Upsert the role of a user in a project, found through the index.
Future<DbMember> setRole(
  SdbDatabase db,
  int userId,
  String projectId,
  String role,
) {
  return memberStore.inTransaction(db, SdbTransactionMode.readWrite, (
    txn,
  ) async {
    var existing = await memberByUserProject
        .record(userId, projectId)
        .getObject(txn);
    if (existing == null) {
      return memberStore.add(
        txn,
        DbMember()
          ..userId.v = userId
          ..projectId.v = projectId
          ..role.v = role,
      );
    }
    existing.role.v = role;
    await existing.put(txn);
    return existing;
  });
}

/// Every membership of a user: tuple keys are ordered by position.
Future<List<DbMember>> userMemberships(SdbClient client, int userId) async {
  var records = await memberByUserProject.findRecords(
    client,
    boundaries: SdbBoundaries(
      memberByUserProject.lowerBoundary(userId, ''),
      memberByUserProject.upperBoundary(userId + 1, ''),
    ),
  );
  return records.map((r) => r.record).toList();
}
```

### Live list driven by an index key

```dart
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

class DbTask extends ScvIntRecordBase {
  final status = CvField<String>('status');
  final title = CvField<String>('title');

  @override
  List<CvField> get fields => [status, title];
}

final taskStore = scvIntStoreFactory.store<DbTask>('task');
final taskByStatus = taskStore.index<String>('status');

final taskSchema = SdbDatabaseSchema(
  stores: [
    taskStore.schema(
      autoIncrement: true,
      indexes: [taskByStatus.schema(keyPath: DbTask().status.name)],
    ),
  ],
);

Future<void> main() async {
  cvAddConstructors([DbTask.new]);
  var db = await newSdbFactoryMemory().openDatabase(
    'tasks.db',
    options: SdbOpenDatabaseOptions(version: 1, schema: taskSchema),
  );

  // Current open tasks first, then every change.
  var subscription = taskByStatus.record('open').onObjects(db).listen((tasks) {
    print('open: ${tasks.map((t) => t.title.v).toList()}');
  });

  var task = await taskStore.add(
    db,
    DbTask()
      ..status.v = 'open'
      ..title.v = 'write',
  );
  await taskStore.add(
    db,
    DbTask()
      ..status.v = 'done'
      ..title.v = 'read',
  );
  task.status.v = 'done';
  await task.put(db); // leaves the 'open' list

  // Count and bulk delete by index key.
  print(await taskByStatus.record('done').count(db)); // 2
  await taskByStatus.record('done').delete(db);
  print(await taskStore.count(db)); // 0

  await Future<void>.delayed(const Duration(milliseconds: 10));
  await subscription.cancel();
  await db.close();
}
```
