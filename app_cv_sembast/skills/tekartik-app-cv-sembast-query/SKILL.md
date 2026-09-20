---
name: tekartik-app-cv-sembast-query
description: >-
  Use when querying, counting, watching or exporting cv records stored in
  sembast with tekartik_app_cv_sembast: store.query(finder:) DbQueryRef with
  getRecord, getRecords, getRecordSync, getRecordsSync, getKeys, count,
  delete and the change streams onRecord, onRecords, onRecordSync,
  onRecordsSync, onCount, onKeys; store.find / findFirst; DbRecordRef.onRecord
  / onRecordSync and DbRecordsRef.onRecords; sembast Finder, Filter,
  SortOrder built from CvField names; json export with toJsonEncodable,
  dbToJson, dbToJsonPretty (Timestamp and Blob encoded) and
  cvSembastFillOptions1 test data. Defining and writing records is in
  tekartik-app-cv-sembast-records.
---

# Query and watch cv records in sembast (tekartik_app_cv_sembast)

A `DbQueryRef<K, V>` (from `store.query(finder:)`) wraps a sembast
`QueryRef` and returns typed `V` records instead of snapshots, both for one
shot reads and for change streams. Records and stores are described in the
`tekartik-app-cv-sembast-records` skill.

## Guidelines

* Import `package:tekartik_app_cv_sembast/app_cv_sembast.dart` (re-exports
  `cv` and `sembast`, so `Finder`, `Filter`, `SortOrder` and `Field` are
  available).
* `store.query({finder})` builds the query; `rawRef` is the sembast
  `QueryRef`. `Finder(filter:, sortOrders:, limit:, offset:, start:, end:)`
  is plain sembast: `Filter.equals(field, value)`, `Filter.notEquals`,
  `Filter.greaterThan`, `Filter.lessThan`, `Filter.matches(field, regexp)`,
  `Filter.inList`, `Filter.isNull`, `Filter.and([...])`, `Filter.or([...])`,
  `Filter.custom((snapshot) => ...)`; `SortOrder(field, ascending)`;
  `Field.key` sorts or filters on the key. Take field names from a model
  instance (`final dbTaskModel = DbTask(); ... dbTaskModel.title.name`)
  rather than string literals so renames are caught at compile time.
* One shot reads take a `DatabaseClient` (`Database` or `Transaction`):
  `getRecords(client)` (`List<V>`), `getRecord(client)` (first or `null`),
  the `getRecordsSync` / `getRecordSync` variants (no `await`, sembast
  data is in memory), `getKeys(client)` / `getKeysSync`, `count(client)` /
  `countSync`, `delete(client)` (returns the number deleted).
  `store.find(client, finder:)` and `store.findFirst(client, finder:)` are
  shortcuts for `query(finder: finder).getRecords` / `.getRecord`;
  `store.delete(client, finder:)` deletes the matches.
* Streams need the `Database` (not a transaction): `onRecords(db)`
  (`Stream<List<V>>`), `onRecord(db)` (`Stream<V?>`, first match),
  `onCount(db)`, `onKeys(db)`. They emit the current result first, then
  again on every change of the store. The `*Sync` variants
  (`onRecordsSync`, `onRecordSync`, `onCountSync`, `onKeysSync`) emit that
  first event synchronously during `listen`, so a UI can render without a
  loading state. Cancel subscriptions when done.
* Single records: `store.record(key).onRecord(db)` / `onRecordSync(db)`
  (`Stream<V?>`, `null` when absent); `store.records(keys).onRecords(db)`
  (`Stream<List<V?>>`).
* Records returned by reads and streams carry their ref: change fields and
  `await record.put(db)`; use `record.id` as the list key in UI code.
* Filters run in memory: keep stores reasonably sized, add `limit` /
  `offset` for pagination and keep sort orders stable (append
  `SortOrder(Field.key)`).
* JSON (extensions on `DbRecord` and on `List<DbRecord>`):
  `toJsonEncodable({columns, includeMissingValue, codec})` converts the
  map with `sembastDefaultJsonEncodableCodec` (a `Timestamp` becomes
  `{'@Timestamp': iso}`, a `Blob` `{'@Blob': base64}`), `dbToJson()` and
  `dbToJsonPretty()` (2 spaces) encode it. Pass another sembast
  `JsonEncodableCodec` as `codec` for custom type adapters. The other way:
  `jsonDecode`, then `sembastDefaultJsonEncodableCodec.decode` (from
  `package:sembast/utils/type_adapter.dart`), then `cvBuildModel<T>(map)
  ..fromMap(map)`.
* `cvSembastFillOptions1` is a `CvFillOptions` for `record.fillModel(...)`
  in tests: ints from 1, `Timestamp(n, 0)`, a `Blob` of `n` bytes, maps
  `{'value': n}`; its output is frozen so golden expectations stay valid.

## Examples

### Filter, sort, paginate and count

```dart
import 'package:sembast/timestamp.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

class DbTask extends DbIntRecordBase {
  final title = CvField<String>('title');
  final done = CvField<bool>('done');
  final dueAt = CvField<Timestamp>('dueAt');

  @override
  List<CvField> get fields => [title, done, dueAt];
}

final dbTaskModel = DbTask();
final taskStore = dbIntStoreFactory.store<DbTask>('task');

/// Pending tasks, earliest due first, 20 at a time.
Future<List<DbTask>> pendingTasks(DatabaseClient client, {int page = 0}) {
  return taskStore
      .query(
        finder: Finder(
          filter: Filter.equals(dbTaskModel.done.name, false),
          sortOrders: [
            SortOrder(dbTaskModel.dueAt.name),
            SortOrder(Field.key),
          ],
          limit: 20,
          offset: page * 20,
        ),
      )
      .getRecords(client);
}

Future<int> overdueCount(DatabaseClient client) => taskStore
    .query(
      finder: Finder(
        filter: Filter.and([
          Filter.equals(dbTaskModel.done.name, false),
          Filter.lessThan(dbTaskModel.dueAt.name, Timestamp.now()),
        ]),
      ),
    )
    .count(client);

Future<void> markAllDone(Database db) => db.transaction((txn) async {
  var pending = await taskStore.find(
    txn,
    finder: Finder(filter: Filter.equals(dbTaskModel.done.name, false)),
  );
  for (var task in pending) {
    task.done.v = true;
  }
  await pending.put(txn);
});
```

### Watch a query and a single record

```dart
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

class DbMessage extends DbStringRecordBase {
  final text = CvField<String>('text');

  @override
  List<CvField> get fields => [text];
}

final messageStore = dbStringStoreFactory.store<DbMessage>('message');

Future<void> main() async {
  cvAddConstructors([DbMessage.new]);
  var db = await newDatabaseFactoryMemory().openDatabase('chat.db');

  // First event delivered synchronously with the current content.
  var subscription = messageStore
      .query(finder: Finder(sortOrders: [SortOrder(Field.key)]))
      .onRecordsSync(db)
      .listen((messages) {
        print(messages.map((m) => '${m.id}: ${m.text.v}').join(', '));
      });
  var single = messageStore.record('m1').onRecord(db).listen((message) {
    print('m1 is now ${message?.text.v}');
  });

  await (messageStore.record('m1').cv()..text.v = 'hello').put(db);
  await (messageStore.record('m2').cv()..text.v = 'world').put(db);
  await messageStore.record('m1').delete(db);

  await Future<void>.delayed(const Duration(milliseconds: 10));
  await subscription.cancel();
  await single.cancel();
  await db.close();
}
```

### Export and import as json

```dart
import 'dart:convert';

import 'package:sembast/timestamp.dart';
import 'package:sembast/utils/type_adapter.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

class DbEvent extends DbIntRecordBase {
  final name = CvField<String>('name');
  final at = CvField<Timestamp>('at');

  @override
  List<CvField> get fields => [name, at];
}

final eventStore = dbIntStoreFactory.store<DbEvent>('event');

/// Every event as pretty json (a Timestamp becomes {"@Timestamp": ...}).
Future<String> exportEvents(DatabaseClient client) async {
  var events = await eventStore.find(client);
  return events.dbToJsonPretty();
}

/// Import a list produced by [exportEvents] (keys are regenerated).
Future<void> importEvents(Database db, String json) async {
  var list = sembastDefaultJsonEncodableCodec.decode(jsonDecode(json) as Object) as List;
  var events = [
    for (var map in list.cast<Map>()) cvBuildModel<DbEvent>(map)..fromMap(map),
  ];
  await db.transaction((txn) async {
    for (var event in events) {
      await eventStore.add(txn, event);
    }
  });
}

/// Deterministic sample for tests.
DbEvent sampleEvent() => DbEvent()..fillModel(cvSembastFillOptions1);
```
