# tekartik_app_cv_firestore

Typed firestore documents: [cv](https://pub.dev/packages/cv) models
(`CvFirestoreDocumentBase`) read and written through
[tekartik_firebase_firestore](https://github.com/tekartik/firebase_firestore.dart),
with path only references (`CvCollectionReference<T>`,
`CvDocumentReference<T>`) and typed queries (`CvQueryReference<T>`).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`); the example
below also uses the in memory firestore of `tekartik_firebase_firestore_sembast`:

```yaml
dependencies:
  tekartik_app_cv_firestore:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_cv_firestore
  tekartik_firebase_firestore_sembast:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_sembast
```

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';

class Note extends CvFirestoreDocumentBase {
  final title = CvField<String>('title');
  final done = CvField<bool>('done');

  @override
  List<CvField> get fields => [title, done];
}

/// Path only, declared once.
final notes = CvCollectionReference<Note>('notes');

Future<void> main() async {
  // Once, before any read.
  cvFirestoreAddBuilder<Note>((_) => Note());

  var firestore = newFirestoreMemory();
  var note = await notes.add(
    firestore,
    Note()
      ..title.v = 'Buy milk'
      ..done.v = false,
  );
  print(note.path); // notes/<generated id>

  var read = await notes.doc(note.id).get(firestore);
  print('${read.exists} ${read.title.v}'); // true Buy milk

  var todo = await notes.query().where('done', isEqualTo: false).get(firestore);
  print(todo.length); // 1
}
```

See [example/main.dart](example/main.dart).

## Platforms

Pure Dart, on any `Firestore` of tekartik_firebase_firestore: the Flutter
plugin one, REST, Firebase admin (node), the sembast local or in memory one
(tests).

## What to use

* `CvFirestoreDocumentBase`: your model, its `fields` list, plus `path`,
  `id`, `exists`.
* `CvCollectionReference<T>` / `CvDocumentReference<T>`: `get`, `set`,
  `update`, `add`, `delete`, `onSnapshot(s)`, `query()`, all taking the
  `Firestore`.
* `CvQueryReference<T>`: `where`, `orderBy`, `limit`, cursors, `get`,
  `count`, `onSnapshots`, `delete`.
* Extensions on the raw objects: `firestore.cvGet<T>(path)`,
  `firestore.cvSet(document)`, `snapshot.cv<T>()`, `firestore.cvBatch()`,
  `firestore.cvRunTransaction(...)`.

## Common pitfalls

* Register a builder per type (`cvFirestoreAddBuilder<T>((_) => T())`)
  before reading: a read, `clone()` or `fsClone()` of an unregistered type
  throws (`Missing builder for 'T'`).
* Reading a missing document does not throw: check `exists`.
* `get` returns a read only list (documents converted on access): copy it
  (`toList()`) before `sort`.
* `cvSet`/`cvUpdate` need a document with a path; `add` creates the id.
* On a service without track changes support `onSnapshot(s)` polls, every
  hour by default (`onSnapshotsSupport(firestore, options:
  TrackChangesSupportOptions(refreshDelay: ...))` to change it).
* A query stream (`onSnapshots`) sends the query errors (i.e. a rules
  denial, a missing index) to its listener and closes with the query stream
  since 2026-11-10; before, the error was uncaught and the stream never
  ended.
* `toInfoJsonList()` on a `List<CvFirestoreDocument>` (the base type itself)
  does not compile (two extensions): use a typed list.

## Agent skills

[models](skills/tekartik-app-cv-firestore-models/SKILL.md),
[crud](skills/tekartik-app-cv-firestore-crud/SKILL.md),
[query](skills/tekartik-app-cv-firestore-query/SKILL.md).
