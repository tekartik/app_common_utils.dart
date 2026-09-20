---
name: tekartik-app-cv-firestore-query
description: >-
  Use when querying typed firestore documents with tekartik_app_cv_firestore:
  CvQueryReference, collection.query(), where (isEqualTo, isGreaterThan,
  arrayContains, whereIn, isNull), orderBy, orderById, limit, select, startAt,
  startAfter, endAt, endBefore, get, count, onSnapshots, onSnapshotsSupport,
  the query delete(firestore, limit, batchSize, keepIds) helper, rawSync and
  rawASync.
---

# Typed queries (tekartik_app_cv_firestore)

`CvQueryReference<T>` is a path-only, immutable query builder: it is created
from a `CvCollectionReference<T>`, chained like a firestore `Query`, and
executed by passing the `Firestore` instance. Results come back as typed
documents (see the `-models` and `-crud` sibling skills).

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
  Import `package:tekartik_app_cv_firestore/app_cv_firestore.dart` and
  register the builders (`cvFirestoreAddBuilder<T>((_) => T())`) before
  running a query.
* Create with `collection.query()` (never with the constructor directly, it
  is `@internal`). Each builder method returns a **new** query, so assign the
  result: `query = query.where(...).limit(10)`.
* Filters: `where(fieldPath, {isEqualTo, isLessThan, isLessThanOrEqualTo,
  isGreaterThan, isGreaterThanOrEqualTo, arrayContains, arrayContainsAny,
  whereIn, isNull})`. `fieldPath` is the firestore field name (the string
  given to `CvField`), which is also `field.name` on your model - prefer
  `myDoc.someField.name` over a literal so a rename cannot desync.
* Ordering and shaping: `orderBy(key, descending: true)` (repeat for several
  keys, may need a firestore index), `orderById(descending: ...)`,
  `limit(n)`, `select([keyPaths])` to fetch a subset of fields (the missing
  fields are simply absent from the resulting documents).
* Cursors: `startAt`, `startAfter`, `endAt`, `endBefore`, each taking either
  `values: [...]` matching the `orderBy` keys, or `snapshot:` a raw
  `DocumentSnapshot`. Page by re-running the query with
  `startAfter(values: [lastDocument.field.v])`, or keep `orderById()` and
  page on the id.
* Execution, all taking the `Firestore`: `get(firestore)` returns
  `List<T>`, `count(firestore)` returns the match count without reading the
  documents, `onSnapshots(firestore)` is a `Stream<List<T>>` that works even
  on services without track-changes support (polling), and
  `onSnapshotsSupport(firestore, options: TrackChangesPullOptions(...))` tunes
  it. `onSnapshot` (singular) on a query is deprecated: use `onSnapshots`.
* Bulk delete: `await query.delete(firestore, limit: 100, batchSize: 50,
  keepIds: ['keep-me'])` (extension `CvFirestoreQueryReferenceUtilsExt`)
  deletes the matching documents in batches and returns how many were
  deleted. Pass `limit:` explicitly - a `limit()` set on the query is ignored
  by this helper. Great for test cleanup and for pruning old records.
* Escape hatches: `rawSync(firestore)` gives the underlying `Query` when no
  cursor needs a document read, `rawASync(firestore)` is the async variant
  (a cursor built from a document id must read it first). `query.cvGet<T>()`
  and `query.cvOnSnapshots<T>()` are the same conversions on a raw `Query`.
* `cast<U>()` re-types a query (and `collection.cast<U>()` a collection) when
  the same physical collection is read through different models; `type`
  returns the current document `Type`.
* Anti-patterns: expecting the builder methods to mutate in place; using a
  field name string that does not match the `CvField` name; calling
  `delete(firestore)` with only `limit()` on the query; ordering by a field
  that many documents do not have (they are excluded by firestore);
  forgetting that composite `where` + `orderBy` combinations need an index on
  a real firestore backend.

## Examples

### Filter, order and page

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Article extends CvFirestoreDocumentBase {
  final title = CvField<String>('title');
  final published = CvField<bool>('published');
  final date = CvField<Timestamp>('date');
  final tags = CvListField<String>('tags');

  @override
  List<CvField> get fields => [title, published, date, tags];
}

final articles = CvCollectionReference<Article>('articles');

Future<List<Article>> lastPublished(Firestore firestore, {Article? after}) {
  var query = articles
      .query()
      .where('published', isEqualTo: true)
      .orderBy('date', descending: true)
      .limit(20);
  var last = after?.date.v;
  if (last != null) {
    query = query.startAfter(values: [last]);
  }
  return query.get(firestore);
}

Future<void> demo(Firestore firestore) async {
  cvFirestoreAddBuilder<Article>((_) => Article());
  var page1 = await lastPublished(firestore);
  var page2 = await lastPublished(firestore, after: page1.lastOrNull);
  print('${page1.length} + ${page2.length}');

  // Field names come from the model, not from literals.
  var sample = Article();
  var tagged = await articles
      .query()
      .where(sample.tags.name, arrayContains: 'dart')
      .get(firestore);
  print(tagged.length);
}
```

### Count, select and watch

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Device extends CvFirestoreDocumentBase {
  final name = CvField<String>('name');
  final online = CvField<bool>('online');
  final payload = CvField<Model>('payload');

  @override
  List<CvField> get fields => [name, online, payload];
}

final devices = CvCollectionReference<Device>('devices');

Future<void> demo(Firestore firestore) async {
  cvFirestoreAddBuilder<Device>((_) => Device());
  var onlineQuery = devices.query().where('online', isEqualTo: true);

  print(await onlineQuery.count(firestore)); // no document read

  // Only the name field is fetched.
  var names = await onlineQuery.select(['name']).get(firestore);
  print(names.map((device) => device.name.v).toList());

  // Live updates, polling if the backend has no track changes support.
  var subscription = onlineQuery.onSnapshots(firestore).listen((list) {
    print('${list.length} online');
  });
  await Future<void>.delayed(const Duration(seconds: 1));
  await subscription.cancel();
}
```

### Prune old documents / clean a test collection

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class LogEntry extends CvFirestoreDocumentBase {
  final message = CvField<String>('message');
  final date = CvField<Timestamp>('date');

  @override
  List<CvField> get fields => [message, date];
}

final logs = CvCollectionReference<LogEntry>('logs');

Future<int> pruneOldLogs(Firestore firestore, Timestamp before) async {
  // limit must be passed here, a limit() on the query is ignored.
  return logs
      .query()
      .where('date', isLessThan: before)
      .orderBy('date')
      .delete(firestore, limit: 500, batchSize: 50);
}

Future<void> clearAll(Firestore firestore, {List<String>? keepIds}) =>
    logs.query().delete(firestore, keepIds: keepIds);
```

### Dropping down to the raw query

```dart
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

class Item extends CvFirestoreDocumentBase {
  final label = CvField<String>('label');

  @override
  List<CvField> get fields => [label];
}

final items = CvCollectionReference<Item>('items');

Future<void> demo(Firestore firestore) async {
  cvFirestoreAddBuilder<Item>((_) => Item());

  // Raw Query, typed result.
  Query raw = items.query().orderById().limit(5).rawSync(firestore);
  List<Item> list = await raw.cvGet<Item>();
  print(list.length);

  // Cursor on a raw snapshot.
  var snapshot = await firestore.doc('${items.path}/i1').get();
  var next = await items
      .query()
      .orderById()
      .startAfter(snapshot: snapshot)
      .get(firestore);
  print(next.length);
}
```
