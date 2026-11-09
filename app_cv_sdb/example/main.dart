// ignore_for_file: avoid_print

import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

/// A note, stored with an int key.
class DbNote extends ScvIntRecordBase {
  final title = CvField<String>('title');
  final createdAt = CvField<SdbTimestamp>('createdAt');

  @override
  CvFields get fields => [title, createdAt];
}

/// Store and index references, top level finals.
final noteStore = scvIntStoreFactory.store<DbNote>('note');
final noteByTitle = noteStore.index<String>('by_title');

/// The schema: stores and indexes are created when the version increases.
final dbSchema = SdbDatabaseSchema(
  stores: [
    noteStore.schema(
      autoIncrement: true,
      indexes: [noteByTitle.schema(keyPath: 'title')],
    ),
  ],
);

Future<void> main() async {
  // Once, before any read.
  cvAddConstructors([DbNote.new]);

  // newSdbFactoryMemory() for tests, sdbFactoryWeb (browser IndexedDB),
  // sdbFactoryIo (VM files) or idb_sqflite's sdbFactoryFromSqflite (Flutter).
  var db = await newSdbFactoryMemory().openDatabase(
    'notes.db',
    options: SdbOpenDatabaseOptions(version: 1, schema: dbSchema),
  );

  // Generated key: the returned record carries it.
  var note = await noteStore.add(
    db,
    DbNote()
      ..title.v = 'Groceries'
      ..createdAt.v = SdbTimestamp.now(),
  );
  print('added ${note.id}'); // 1

  // Chosen key.
  await (noteStore.record(10).cv()..title.v = 'Ideas').put(db);

  // Read, modify, save.
  var ideas = (await noteStore.record(10).get(db))!;
  ideas.title.v = 'Ideas 2026';
  await ideas.put(db);

  // Queries: all the records, a lookup by index.
  var notes = await noteStore.findRecords(db);
  print(notes.map((note) => note.title.v).toList()); // [Groceries, Ideas 2026]
  var found = await noteByTitle.record('Groceries').getObject(db);
  print('found ${found?.id}'); // 1

  // Several writes in one transaction.
  await noteStore.inTransaction(db, SdbTransactionMode.readWrite, (txn) async {
    await noteStore.record(1).delete(txn);
    await noteStore.record(2).put(txn, DbNote()..title.v = 'Todo');
  });
  print(await noteStore.count(db)); // 2

  await db.close();
}
