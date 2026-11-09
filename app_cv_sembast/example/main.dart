// ignore_for_file: avoid_print

import 'package:sembast/sembast_memory.dart';
import 'package:sembast/timestamp.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

/// A note, stored with an int key.
class DbNote extends DbIntRecordBase {
  final title = CvField<String>('title');
  final done = CvField<bool>('done');
  final createdAt = CvField<Timestamp>('createdAt');

  @override
  CvFields get fields => [title, done, createdAt];
}

/// Store reference, a top level final.
final noteStore = dbIntStoreFactory.store<DbNote>('note');

/// A model instance to get the field names for the finders.
final dbNoteModel = DbNote();

Future<void> main() async {
  // Once, before any read.
  cvAddConstructors([DbNote.new]);

  // databaseFactoryIo (sembast_io.dart) on the VM and Flutter,
  // databaseFactoryWeb (sembast_web) in the browser.
  var db = await newDatabaseFactoryMemory().openDatabase('notes.db');

  // Generated key: the instance gets its id.
  var note = await noteStore.add(
    db,
    DbNote()
      ..title.v = 'Groceries'
      ..done.v = false
      ..createdAt.v = Timestamp.now(),
  );
  print('added ${note.id}'); // 1

  // Chosen key.
  await (noteStore.record(10).cv()
        ..title.v = 'Ideas'
        ..done.v = true)
      .put(db);

  // Read, modify, save.
  var groceries = (await noteStore.record(note.id).get(db))!;
  groceries.done.v = true;
  await groceries.put(db);

  // Query with a sembast Finder.
  var doneNotes = await noteStore.find(
    db,
    finder: Finder(
      filter: Filter.equals(dbNoteModel.done.name, true),
      sortOrders: [SortOrder(dbNoteModel.title.name)],
    ),
  );
  print(doneNotes.map((note) => note.title.v).toList()); // [Groceries, Ideas]

  // Change stream: current content first, then each change.
  var subscription = noteStore.query().onRecords(db).listen((notes) {
    print('${notes.length} note(s)');
  });
  await db.transaction((txn) async {
    await noteStore.record(10).delete(txn);
  });
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await subscription.cancel();

  print(groceries.dbToJson()); // {"title":"Groceries","done":true,...}
  await db.close();
}
