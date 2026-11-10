// ignore_for_file: avoid_print

import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';

/// A typed document.
class Note extends CvFirestoreDocumentBase {
  final title = CvField<String>('title');
  final done = CvField<bool>('done');
  final rank = CvField<int>('rank');

  @override
  List<CvField> get fields => [title, done, rank];
}

/// References hold a path only, declare them once.
final notes = CvCollectionReference<Note>('notes');

Future<void> main() async {
  // Once, before any read.
  cvFirestoreAddBuilder<Note>((_) => Note());

  // In memory firestore, same API as the real ones.
  var firestore = newFirestoreMemory();

  // Create: add generates the id, set uses the given path.
  var milk = await notes.add(
    firestore,
    Note()
      ..title.v = 'Buy milk'
      ..done.v = false
      ..rank.v = 2,
  );
  await notes
      .doc('bread')
      .set(
        firestore,
        Note()
          ..title.v = 'Buy bread'
          ..done.v = false
          ..rank.v = 1,
      );

  // Read: a missing document does not throw.
  var read = await notes.doc(milk.id).get(firestore);
  print('${read.id}: ${read.title.v}');
  print(
    'missing exists: ${(await notes.doc('missing').get(firestore)).exists}',
  );

  // Query.
  var todo = await notes
      .query()
      .where('done', isEqualTo: false)
      .orderBy('rank')
      .get(firestore);
  print('todo: ${todo.map((note) => note.title.v).toList()}');

  // Update with a batch.
  var batch = firestore.cvBatch();
  batch.cvSet(read..done.v = true);
  await batch.commit();
  print(
    'left: ${await notes.query().where('done', isEqualTo: false).count(firestore)}',
  );

  // Live query, errors are delivered to the listener.
  var first = await notes.query().orderBy('rank').onSnapshots(firestore).first;
  print('snapshot: ${first.map((note) => note.id).toList()}');
}
