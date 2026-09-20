---
name: tekartik-app-cv-firestore-crud
description: >-
  Use when reading, writing, batching or running transactions on typed
  firestore documents with tekartik_app_cv_firestore: CvCollectionReference,
  CvDocumentReference, cvGet, cvSet, cvAdd, cvUpdate, docDelete, refGet,
  refSet, refDelete, pathDelete, snapshot.cv<T>(), cvOnSnapshot,
  cvOnSnapshots, cvBatch/CvFirestoreWriteBatch, cvRunTransaction/
  CvFirestoreTransaction, raw() and newFirestoreMemory in tests.
---

# Typed reads and writes (tekartik_app_cv_firestore)

Once documents extend `CvFirestoreDocumentBase` (see the `-models` sibling
skill), `tekartik_app_cv_firestore` offers two equivalent styles: typed
path objects (`CvCollectionReference<T>` / `CvDocumentReference<T>`, which
take the `Firestore` as an argument) and extensions on the raw firestore
objects (`firestore.cvGet<T>(path)`, `snapshot.cv<T>()`).

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
* One import for everything:
  `package:tekartik_app_cv_firestore/app_cv_firestore.dart` (it re-exports
  `cv` and `tekartik_firebase_firestore`). Register the builders
  (`cvFirestoreAddBuilder<T>((_) => T())`) before any read.
* Reference objects hold **only a path**, no firestore instance: declare them
  as `const`-like top level values or getters and pass the `Firestore` to each
  call.
  * `CvCollectionReference<T>('users')`: `doc(id)`, `get(firestore)`,
    `add(firestore, document)` (path of the document is ignored, the returned
    document carries the new path), `addMap(firestore, model)`,
    `count(firestore)`, `onSnapshots(firestore)`, `query()`, `raw(firestore)`,
    `cast<U>()`, `withPath(path)`, `withId(id)`, `parent`.
  * `CvDocumentReference<T>('users/1')`: `get(firestore)`,
    `set(firestore, doc, [options])`, `setMap(firestore, model, [options])`,
    `update(firestore, doc)`, `updateMap(firestore, model)`,
    `delete(firestore)`, `onSnapshot(firestore)`, `cv()` (an empty typed
    document with that path), `collection<U>('sub')`, `parent`, `raw(
    firestore)`, `cast<U>()`, `withId(id)`.
  * `cvRootDocumentReference` is the empty-path root: use
    `cvRootDocumentReference.collection<T>('users')` to build top level
    collections from one place.
* Extensions on `Firestore` when you already have a path or a document:
  `cvGet<T>(path)`, `cvSet(document)`, `cvUpdate(document)` /
  `docUpdate(document)`, `docDelete(document)`, `cvAdd<T>(path, document)`,
  `refGet(ref)`, `refSet(ref, document)`, `refDelete(ref)`,
  `pathDelete(path)`. Every call that takes a document requires `path` to be
  set (`hasId` true) and throws `ArgumentError` otherwise.
* Extensions on raw firestore objects: `documentSnapshot.cv<T>()` (and
  `cvType<T>(type)` for a runtime type), `querySnapshot.cv<T>()`,
  `List<DocumentSnapshot>.cv<T>()`, `documentReference.cvGet<T>()`,
  `collectionReference.cvAdd(document)`, `query.cvGet<T>()`, and
  `collectionReference.cv<T>()` / `documentReference.cv<T>()` to get back a
  typed `Cv*Reference`.
* Reading a missing document does not throw: you get a typed document with
  `exists == false` and empty fields - always check `exists` before using
  the values.
* Streams: `ref.onSnapshot(firestore)` / `collection.onSnapshots(firestore)`
  (and `docRef.cvOnSnapshot<T>()` / `query.cvOnSnapshots<T>()` on raw
  objects) work even on a service without track-changes support, by polling.
  Use the `*Support(firestore, options: TrackChangesPullOptions(...))`
  variants to tune the polling.
* Batch: `var batch = firestore.cvBatch();` then `cvSet(document)`,
  `cvUpdate(document)`, `refSet(ref, document)`, `refSetMap(ref, model)`,
  `refUpdate(ref, document)`, `refUpdateMap(ref, model)`, `refDelete(ref)`,
  `cvDelete(path)`, and `await batch.commit()`. `CvFirestoreWriteBatch` also
  keeps the raw `set`/`update`/`delete`.
* Transaction: `await firestore.cvRunTransaction((txn) async { ... })` gives a
  `CvFirestoreTransaction` with `cvGet<T>(path)`, `refGet(ref)`,
  `cvSet(document)`, `refSet(ref, document)`, `refSetMap(ref, model)`,
  `cvUpdate(document)`, `refUpdate(ref, document)`, `refUpdateMap(ref, model)`,
  `docDelete(document)`, `refDelete(ref)`, `pathDelete(path)`. Read before
  write inside the transaction, and remember an `update` on a missing document
  fails the transaction.
* `SetOptions(merge: true)` is accepted by every `set`/`refSet` variant when a
  partial write is wanted; otherwise `set` replaces the whole document.
  `update` only touches the map keys present in `toMap()`.
* Testing: `newFirestoreMemory()` from
  `package:tekartik_firebase_firestore_sembast/firestore_sembast.dart`
  (dev dependency, git url `https://github.com/tekartik/firebase_firestore.dart`,
  `path: firestore_sembast`) gives an in-memory `Firestore` with the same API;
  register the builders in `setUpAll`.
* Anti-patterns: calling `firestore.cvSet` on a document without a path (use
  `collection.add`); reusing a document returned by a stream without
  `fsClone()`; rebuilding `CvCollectionReference` objects inline everywhere
  instead of declaring them once; forgetting `await batch.commit()`.

## Examples

### References declared once, CRUD on a typed document

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class User extends CvFirestoreDocumentBase {
  final name = CvField<String>('name');
  final age = CvField<int>('age');

  @override
  List<CvField> get fields => [name, age];
}

/// Paths declared once, firestore passed at call time.
final userCollection = CvCollectionReference<User>('users');
CvDocumentReference<User> userRef(String id) => userCollection.doc(id);

Future<void> demo(Firestore firestore) async {
  cvFirestoreAddBuilder<User>((_) => User());

  // Create with a generated id.
  var created = await userCollection.add(firestore, User()..name.v = 'Alice');
  print('${created.id} ${created.path}');

  // Create/replace with a known id.
  var bob = userRef('bob').cv()
    ..name.v = 'Bob'
    ..age.v = 30;
  await userRef('bob').set(firestore, bob);

  // Partial update.
  await userRef('bob').update(firestore, User()..age.v = 31);

  // Read, checking existence.
  var read = await userRef('bob').get(firestore);
  if (read.exists) {
    print('${read.name.v} ${read.age.v}');
  }

  // List and delete.
  var all = await userCollection.get(firestore);
  print(all.map((user) => user.id).toList());
  await userRef('bob').delete(firestore);
}
```

### Firestore extensions and sub collections

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Post extends CvFirestoreDocumentBase {
  final title = CvField<String>('title');

  @override
  List<CvField> get fields => [title];
}

Future<void> demo(Firestore firestore) async {
  cvFirestoreAddBuilder<Post>((_) => Post());

  var posts = cvRootDocumentReference
      .collection<Post>('users')
      .doc('1')
      .collection<Post>('posts');

  // Path based helpers on Firestore itself.
  var post = Post()
    ..path = '${posts.path}/p1'
    ..title.v = 'hello';
  await firestore.cvSet(post, SetOptions(merge: true));
  var read = await firestore.cvGet<Post>(post.path);
  print('${read.exists} ${read.title.v}');
  await firestore.docDelete(read);

  // Raw firestore objects convert both ways.
  var snapshot = await firestore.doc(post.path).get();
  print(snapshot.cv<Post>().exists);
  var typedRef = firestore.doc(post.path).cv<Post>();
  print(typedRef.path);
}
```

### Batch and transaction

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Counter extends CvFirestoreDocumentBase {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

final counters = CvCollectionReference<Counter>('counters');

Future<void> demo(Firestore firestore) async {
  cvFirestoreAddBuilder<Counter>((_) => Counter());

  // Several writes, one commit.
  var batch = firestore.cvBatch();
  for (var i = 0; i < 3; i++) {
    batch.refSet(counters.doc('c$i'), Counter()..value.v = i);
  }
  batch.refDelete(counters.doc('old'));
  await batch.commit();

  // Read then write atomically.
  await firestore.cvRunTransaction((txn) async {
    var ref = counters.doc('c0');
    var counter = await txn.refGet(ref);
    var next = (counter.exists ? counter.value.v ?? 0 : 0) + 1;
    txn.refSet(ref, Counter()..value.v = next);
  });
  print((await counters.doc('c0').get(firestore)).value.v);
}
```

### Streaming and testing in memory

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';

class Item extends CvFirestoreDocumentBase {
  final label = CvField<String>('label');

  @override
  List<CvField> get fields => [label];
}

final items = CvCollectionReference<Item>('items');

void main() {
  late Firestore firestore;
  setUpAll(() {
    cvFirestoreAddBuilder<Item>((_) => Item());
  });
  setUp(() {
    firestore = newFirestoreMemory();
  });

  test('write and watch', () async {
    var first = items.onSnapshots(firestore).first;
    await items.doc('1').set(firestore, Item()..label.v = 'one');
    expect((await first).length, anyOf(0, 1));
    expect((await items.get(firestore)).single.label.v, 'one');
    expect(await items.count(firestore), 1);
  });
}
```
