---
name: tekartik-app-cv-firestore-models
description: >-
  Use when declaring typed firestore documents with tekartik_app_cv_firestore:
  CvFirestoreDocumentBase, CvFirestoreDocument, CvFirestoreMapDocument,
  cvFirestoreAddBuilder, CvField/CvListField/CvModelField, id, path, hasId,
  exists, ref, idOrNull, refOrNull, fsClone, WithServerTimestampMixin,
  toMapWithServerTimestamp, withServerTimestamp, withDelete, toInfoJson,
  infoJsonToDocument, cvFirestoreFillOptions1 and the app_cv_firestore.dart
  import.
---

# Typed firestore documents (tekartik_app_cv_firestore)

`tekartik_app_cv_firestore` binds `package:cv` models to
`tekartik_firebase_firestore`: a document class declares its fields once and
gets typed reads/writes, plus a `path`/`id`/`exists` identity. This skill
covers declaring the models; see the `-crud` and `-query` sibling skills for
reading and writing them.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the
  `app_cv_firestore/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_cv_firestore:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_cv_firestore
  ```
  A test/dev in-memory firestore comes from the same family:
  ```yaml
  dev_dependencies:
    tekartik_firebase_firestore_sembast:
      git:
        url: https://github.com/tekartik/firebase_firestore.dart
        path: firestore_sembast
  ```
* Single import: `package:tekartik_app_cv_firestore/app_cv_firestore.dart`
  (alias of `app_cv_firestore_v2.dart`). It re-exports `package:cv/cv.dart`
  and `package:tekartik_firebase_firestore/firestore.dart`, so `CvField`,
  `Model`, `Firestore`, `Timestamp`, `Blob`, `FieldValue` and `SetOptions`
  come with it - do not add separate imports for those.
* Declare a document by extending `CvFirestoreDocumentBase` and overriding
  `List<CvField> get fields` (`CvFields` is the same type). Fields are
  `final` instance members: `CvField<String>('text')`,
  `CvListField<int>('ints')`, `CvModelField<SubModel>('sub')`. Read/write the
  value with `.v` (`doc.text.v = 'a'`), nullable by nature.
* Register a builder once at startup (before any `cv<T>()` conversion), for
  every document type *and* sub model type:
  `cvFirestoreAddBuilder<MyDoc>((_) => MyDoc());`. Without it, reads throw
  because `cvBuildModel<T>` cannot construct the type. `cvAddConstructor(
  MyDoc.new)` from `cv` works too.
* Identity, provided by the base class: `path` (settable, full firestore path
  like `users/1/posts/2`), `id` (last path segment), `hasId` (false for a new
  document not yet added), `exists` (true only after a read of an existing
  document), and the extension helpers `idOrNull`, `pathOrNull`, `ref`
  (a `CvDocumentReference<T>`), `refOrNull`, plus the `ref =` setter which
  sets `path`. Equality compares content only, not the path.
* `fsClone()` copies content **and** path: use it before mutating a document
  you received from a stream/read, instead of `clone()` which loses the path.
* `CvFirestoreMapDocument()` is the schema-less variant (any key allowed);
  `CvFirestoreMapDocument.withFields([...])` fixes the set of fields. Use a
  typed class whenever the shape is known.
* Server timestamps: on a `Model`, `withServerTimestamp(field)` and
  `withDelete(field)` replace a value with `FieldValue.serverTimestamp` /
  `FieldValue.delete`. Mix `WithServerTimestampMixin` into a document to get a
  `timestamp` `CvField<Timestamp>`, `timedMixinFields` (spread it in
  `fields`) and `toMapWithServerTimestamp()` to write with a server-side time.
* Serialization outside firestore: `document.toInfoJson()` gives
  `{'path': ..., 'data': ...}`, `toInfoJsonList()` does it for a
  `List<CvFirestoreDocument>` or a `List<DocumentSnapshot>`, and
  `infoJsonToDocument<T>(json)` / `infoJsonListToDocumentList<T>(list)` read
  it back (export/import, http payloads, fixtures). `fsDataToJsonMap()` /
  `fsDataFromJsonMap(firestore, map)` handle the data part alone, keeping
  firestore types (`Timestamp`, `Blob`, `DocumentReference`) encodable.
* Tests: `cvFirestoreFillOptions1` is a stable `CvFillOptions` that generates
  values for firestore types (`Timestamp`, `Blob`, `Model`): use
  `doc.fillModel(cvFirestoreFillOptions1)` to build a fully populated
  document. Its behaviour must never change, so golden tests stay valid.
* Anti-patterns: forgetting the builder registration for a nested model type;
  using `clone()` where `fsClone()` is meant; setting `path` on a document you
  are about to `add()` (the path is ignored and overwritten); assuming
  `exists` is true on a freshly constructed document.

## Examples

### Declaring documents and registering builders

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Address extends CvModelBase {
  final city = CvField<String>('city');
  final zip = CvField<String>('zip');

  @override
  List<CvField> get fields => [city, zip];
}

class User extends CvFirestoreDocumentBase {
  final name = CvField<String>('name');
  final age = CvField<int>('age');
  final tags = CvListField<String>('tags');
  final address = CvModelField<Address>('address');
  final created = CvField<Timestamp>('created');

  @override
  List<CvField> get fields => [name, age, tags, address, created];
}

/// Call once, at app/test startup, before any read.
void initBuilders() {
  cvFirestoreAddBuilder<User>((_) => User());
  cvAddBuilder<Address>((_) => Address());
}

void main() {
  initBuilders();
  var user = User()
    ..path = 'users/1'
    ..name.v = 'Alice'
    ..age.v = 42
    ..tags.v = ['admin']
    ..address.v = (Address()..city.v = 'Genève');
  print('${user.id} ${user.hasId} ${user.exists}'); // 1 true false
  print(user.toMap());
}
```

### Path helpers and cloning

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Note extends CvFirestoreDocumentBase {
  final text = CvField<String>('text');

  @override
  List<CvField> get fields => [text];
}

void main() {
  var newNote = Note()..text.v = 'draft';
  print(newNote.hasId); // false
  print(newNote.idOrNull); // null
  print(newNote.refOrNull); // null

  var saved = Note()
    ..path = 'users/1/notes/n1'
    ..text.v = 'hello';
  CvDocumentReference<Note> ref = saved.ref;
  print('${ref.path} ${ref.id} ${ref.parent.path}');

  // Keeps the path, unlike clone().
  var edited = saved.fsClone()..text.v = 'hello again';
  print('${edited.path} ${edited.text.v}');
}
```

### Server timestamp on write

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Event extends CvFirestoreDocumentBase with WithServerTimestampMixin {
  final message = CvField<String>('message');

  @override
  List<CvField> get fields => [...timedMixinFields, message];
}

Future<void> writeEvent(Firestore firestore) async {
  cvFirestoreAddBuilder<Event>((_) => Event());
  var event = Event()
    ..path = 'events/e1'
    ..message.v = 'started';
  // {'timestamp': FieldValue.serverTimestamp, 'message': 'started'}
  await firestore.doc(event.path).set(event.toMapWithServerTimestamp());

  // Same idea on any model map, plus field deletion.
  var map = event.toMap()
    ..withServerTimestamp(event.timestamp)
    ..withDelete(event.message);
  print(map);
}
```

### Export/import documents as json

```dart
import 'dart:convert';

import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Task extends CvFirestoreDocumentBase {
  final title = CvField<String>('title');

  @override
  List<CvField> get fields => [title];
}

void main() {
  cvFirestoreAddBuilder<Task>((_) => Task());
  var tasks = <Task>[
    Task()
      ..path = 'tasks/1'
      ..title.v = 'write skill',
  ];
  var infoJsonList = tasks.toInfoJsonList();
  print(jsonEncode(infoJsonList));
  // [{"path":"tasks/1","data":{"title":"write skill"}}]

  var restored = infoJsonListToDocumentList<Task>(infoJsonList);
  print('${restored.first.path} ${restored.first.title.v}');

  var one = infoJsonToDocument<Task>(infoJsonList.first);
  print(one.ref);
}
```
