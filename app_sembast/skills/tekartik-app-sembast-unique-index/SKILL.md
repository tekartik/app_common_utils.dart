---
name: tekartik-app-sembast-unique-index
description: >-
  Use when a sembast store needs a lookup by a secondary unique field (a code,
  a uuid, an email) with tekartik_app_sembast: store.index<K>('field') giving an
  IndexRef, db.index(indexRef, throwOnConflict: true) giving a DatabaseIndex,
  then dbIndex.record(key) / dbIndex.transactionRecord(txn, key) and the
  DatabaseClientIndexRecord API (getSnapshot, exists, add, put, update, delete),
  indexRef.key(snapshot) and dbIndex.dispose(), from
  package:tekartik_app_sembast/unique_index.dart.
---

# Unique secondary index (tekartik_app_sembast)

Sembast only indexes the primary key. `unique_index.dart` adds an in-memory
`field value -> primary key` map, filled when the index is created and kept up
to date by a store change listener, so a record can be fetched by another
unique field. It is an experimentation shipped as a single file - read
`lib/src/unique_index.dart` if in doubt.

## Guidelines

* Same git dependency as the rest of the package (see
  [tekartik-app-sembast-factory](../tekartik-app-sembast-factory/SKILL.md) for
  the factory and the `pubspec.yaml` block).
* Two imports are needed, `unique_index.dart` does not re-export sembast:
  ```dart
  import 'package:tekartik_app_sembast/sembast.dart';
  import 'package:tekartik_app_sembast/unique_index.dart';
  ```
* Declare the store and the index definition globally, next to each other. The
  store must be a map store (`intMapStoreFactory.store('book')` or
  `stringMapStoreFactory.store('book')`):
  `var codeIndex = bookStore.index<String>('code');` - `K` is the type of the
  indexed field, the returned `IndexRef<K, PK>` holds only `store` and `path`.
* The live index belongs to one opened `Database`: `var dbCodeIndex =
  db.index(codeIndex, throwOnConflict: true);` right after `openDatabase`, and
  never inside a transaction (it scans the store on creation). Keep it for the
  lifetime of the database, and call `dbCodeIndex.dispose()` before/when
  closing the database - after `dispose()` the listener is removed and every
  lookup returns null.
* `throwOnConflict: true` makes the index throw a `StateError` when two records
  end up with the same index key - either while filling the index at creation
  (surfaced by the first index operation you await) or on the write that
  creates the duplicate (sembast rolls that write back and the index stays as
  it was, since 2026-11-10). Without it the last writer wins silently: check
  then write in one transaction to avoid duplicates.
* The map is in memory and updated after each write, inside the transaction:
  when a transaction fails after writing indexed records (an exception in
  your block, or a conflict refused in `addAll` after earlier records), the
  store is rolled back but the map is not. Call `dispose()` and `db.index(...)`
  again after such a failure.
* Lookup: `await dbCodeIndex.record('BOOK001').getSnapshot()` returns a
  `RecordSnapshot<PK, Model>?` (null when the key is unknown) - use
  `snapshot.key` for the primary key and `snapshot.value` / `snapshot['field']`
  for the data. `exists()` returns a bool. Inside a transaction use
  `dbCodeIndex.transactionRecord(txn, key)` so the read joins the transaction.
* `DatabaseClientIndexRecord` also has `add(value)`, `put(value, merge: true)`,
  `update(value)` and `delete()`, acting on the record the index key points
  to. On an unknown index key, `add` and `put` create a record holding the
  index field (`add` returns its primary key), `update` returns null and
  `delete` does nothing. On a known one `add` returns null (nothing written)
  and `put` keeps the index field unless the value sets it (since 2026-11-10:
  a `put` without `merge` used to drop it, the record left the index); a
  value with another index key moves the record. Inserting through the store
  (`bookStore.add(db, {...})`) works too: the listener indexes the record.
* `indexRef.key(snapshot)` / `dbIndex.key(snapshot)` extract the index key from
  a record snapshot (typed `K?`, null when the field is missing). Records
  without the indexed field are simply not in the index.
* Index maintenance happens on every store change (add, update that changes the
  field, delete), so a `put` that moves the field value from `a` to `b` frees
  `a`. The index is rebuilt at every `db.index(...)` call, i.e. after each
  reopen: cost is one `store.find(db)` over the store.
* One field, unique values, single store only. For multi-field, non unique or
  persisted indexes, keep the data denormalized in another store or use
  `tekartik_app_cv_sdb` instead (sdb has real indexes, the choice for new
  code).
* Anti-patterns: creating the index lazily on each lookup; creating it inside
  `db.transaction`; sharing a `DatabaseIndex` across two `Database` instances;
  forgetting `dispose()` in a test that reopens the database.

## Examples

### Declare, fill and read by index key

```dart
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast/unique_index.dart';

/// Our book store.
var bookStore = intMapStoreFactory.store('book');

/// Our index on the `code` field, which is a String.
var codeIndex = bookStore.index<String>('code');

Future<void> main() async {
  var db = await databaseFactoryMemory.openDatabase('books.db');

  // Create the live index once, right after opening the database.
  var dbCodeIndex = db.index(codeIndex, throwOnConflict: true);

  await bookStore.addAll(db, [
    {'code': 'BOOK001', 'title': 'The great book'},
    {'code': 'BOOK002', 'title': 'The simple book'},
  ]);

  var snapshot = (await dbCodeIndex.record('BOOK001').getSnapshot())!;
  print(snapshot['title']); // The great book
  print(snapshot.key); // the int primary key
  print(codeIndex.key(snapshot)); // BOOK001

  print(await dbCodeIndex.record('BOOK404').getSnapshot()); // null
  print(await dbCodeIndex.record('BOOK002').exists()); // true

  // Reading in a transaction.
  await db.transaction((transaction) async {
    var book = (await dbCodeIndex
        .transactionRecord(transaction, 'BOOK002')
        .getSnapshot())!;
    print(book['title']); // The simple book
  });

  dbCodeIndex.dispose();
  await db.close();
}
```

### Enforce uniqueness

```dart
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast/unique_index.dart';

var userStore = stringMapStoreFactory.store('user');
var emailIndex = userStore.index<String>('email');

Future<void> main() async {
  var db = await databaseFactoryMemory.openDatabase('users.db');
  var dbEmailIndex = db.index(emailIndex, throwOnConflict: true);

  await userStore.record('u1').put(db, {'email': 'a@example.com'});

  try {
    // Same email on another record: the index refuses it.
    await userStore.record('u2').put(db, {'email': 'a@example.com'});
  } on StateError catch (e) {
    print('duplicate: $e');
  }

  // The index still points to the first record.
  print((await dbEmailIndex.record('a@example.com').getSnapshot())!.key); // u1

  dbEmailIndex.dispose();
  await db.close();
}
```

### Update and delete through the index

```dart
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast/unique_index.dart';

var bookStore = intMapStoreFactory.store('book');
var codeIndex = bookStore.index<String>('code');

Future<void> main() async {
  var db = await databaseFactoryMemory.openDatabase('books.db');
  var dbCodeIndex = db.index(codeIndex);

  // Insert through the store (or dbCodeIndex.record('BOOK001').add(...)).
  await bookStore.add(db, {'code': 'BOOK001', 'title': 'A book'});

  // Partial update of the record found by code.
  await dbCodeIndex.record('BOOK001').update({'title': 'A better book'});
  await dbCodeIndex.record('BOOK001').put({'read': true}, merge: true);
  print((await dbCodeIndex.record('BOOK001').getSnapshot())!.value);

  // Unknown key: update returns null, it does not insert.
  print(await dbCodeIndex.record('BOOK404').update({'title': 'x'})); // null

  // Changing the indexed field moves the index entry.
  await dbCodeIndex.record('BOOK001').put({'code': 'BOOK009'}, merge: true);
  print(await dbCodeIndex.record('BOOK001').getSnapshot()); // null
  print((await dbCodeIndex.record('BOOK009').getSnapshot())!['title']);

  await dbCodeIndex.record('BOOK009').delete();
  print(await dbCodeIndex.record('BOOK009').getSnapshot()); // null

  dbCodeIndex.dispose();
  await db.close();
}
```
