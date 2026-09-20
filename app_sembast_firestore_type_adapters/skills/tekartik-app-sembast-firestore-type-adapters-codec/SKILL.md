---
name: tekartik-app-sembast-firestore-type-adapters-codec
description: >-
  Use when storing tekartik firestore values (Timestamp, Blob, GeoPoint) in a
  sembast database with tekartik_app_sembast_firestore_type_adapters: open the
  database with codec: sembastFirestoreCodec, or build your own SembastCodec /
  JsonEncodableCodec from sembastFirestoreDefaultTypeAdapters and
  sembastFirestoreDefaultJsonEncodableCodec, plus the individual
  sembastFirestoreTimestampAdapter, sembastFirestoreBlobAdapter and
  sembastFirestoreGeoPointAdapter (encode/decode) from
  package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart.
---

# Firestore types in sembast (tekartik_app_sembast_firestore_type_adapters)

Sembast only stores json encodable values. This package provides the three
sembast type adapters that let a database hold `Timestamp`, `Blob` and
`GeoPoint` of `tekartik_firebase_firestore` (not `cloud_firestore`), and a
ready made `SembastCodec` bundling them.

## Guidelines

* Not on pub.dev, depend on it through git (it brings `sembast` and
  `tekartik_firebase_firestore` along, but declare what you import):
  ```yaml
  dependencies:
    tekartik_app_sembast_firestore_type_adapters:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_sembast_firestore_type_adapters
      version: '>=0.1.0'
  ```
* `import
  'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';`
  exports only `sembastFirestoreCodec`,
  `sembastFirestoreDefaultTypeAdapters`,
  `sembastFirestoreDefaultJsonEncodableCodec`,
  `sembastFirestoreTimestampAdapter`, `sembastFirestoreBlobAdapter` and
  `sembastFirestoreGeoPointAdapter`. Import `package:sembast/sembast.dart` (or
  `package:tekartik_app_sembast/sembast.dart`) and
  `package:tekartik_firebase_firestore/firestore.dart` separately for
  `Database`, `StoreRef`, `Timestamp`, `Blob` and `GeoPoint`.
* Pass the codec on **every** open of that database:
  `await factory.openDatabase(path, codec: sembastFirestoreCodec);`. The codec
  signature is `'firestore'`; opening an existing database without it (or with
  another signature) fails, and opening a plain database with it fails too.
  Pick the codec before the database exists.
* Stored form (plain json, readable in the `.db` file and in an export):
  `Timestamp` -> `{'@FirestoreTimestamp': {'seconds': ..., 'nanoseconds': ...}}`,
  `Blob` -> `{'@FirestoreBlob': '<base64>'}`, `GeoPoint` ->
  `{'@FirestoreGeoPoint': {'latitude': ..., 'longitude': ...}}`. Values come
  back as the original types, so `record.get(db)` returns a map holding real
  `Timestamp`/`Blob`/`GeoPoint` instances.
* Sorting and filtering work on the in-memory values: `Finder(sortOrders:
  [SortOrder('timestamp', true)])` orders `Timestamp` fields chronologically
  (records without the field come first ascending, last descending) because
  `Timestamp` implements `Comparable`.
* `exportDatabase(db)` / `importDatabase(export, factory, path, codec:
  sembastFirestoreCodec)` (from
  `package:sembast/utils/sembast_import_export.dart`) keep the annotated json
  form, so an export can be re-imported into a database opened with the same
  codec.
* The adapters are plain `SembastTypeAdapter` codecs and can be used alone:
  `sembastFirestoreTimestampAdapter.encode(Timestamp(1234, 5678))` gives the
  map, `.decode({...})` gives the `Timestamp` back, and `isType(value)` tells
  whether an adapter handles a value. Handy to convert firestore data to json
  outside of sembast.
* `sembastFirestoreCodec` replaces the sembast default adapters: sembast's own
  `Timestamp`/`Blob` (from `package:sembast/timestamp.dart` and
  `package:sembast/blob.dart`) are no longer handled. When a database mixes
  both worlds, build a codec with
  `[...sembastFirestoreDefaultTypeAdapters, ...sembastDefaultTypeAdapters]` and
  a distinct signature of your own.
* To support another type, write a `SembastTypeAdapter<S, T>` (from
  `package:sembast/utils/type_adapter.dart`, `T` must be json encodable) - the
  three adapters in `lib/src/` of this package are the model - and add it to
  the list of a new `JsonEncodableCodec`.
* Pure Dart: works with any sembast factory (io, sqflite, web, memory). The
  data is json, not encrypted.
* Anti-patterns: opening the same database sometimes with and sometimes
  without the codec; reusing the `'firestore'` signature for a codec with a
  different adapter list; storing `DocumentReference` or `FieldValue` (not
  supported); expecting `cloud_firestore` types to work.

## Examples

### Store firestore values

```dart
import 'dart:typed_data';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

Future<void> main() async {
  var factory = databaseFactoryMemoryFs;
  // The codec is needed at every open of this database.
  var db = await factory.openDatabase('db', codec: sembastFirestoreCodec);

  var store = stringMapStoreFactory.store();
  var record = store.record('test');
  var data = <String, Object?>{
    'int': 1,
    'String': 'text',
    'firestoreTimestamp': Timestamp(1234, 5678),
    'firestoreBlob': Blob(Uint8List.fromList([1, 2, 3])),
    'firestoreGeoPoint': const GeoPoint(1.1, 2.2),
  };
  await record.add(db, data);

  // Same types on the way out.
  var read = (await record.get(db))!;
  print(read['firestoreTimestamp'] as Timestamp);
  print((read['firestoreBlob'] as Blob).data);
  print((read['firestoreGeoPoint'] as GeoPoint).latitude);

  await db.close();
}
```

### Sort by Timestamp and export

```dart
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/utils/sembast_import_export.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

Future<void> main() async {
  var factory = databaseFactoryMemoryFs;
  var db = await factory.openDatabase('events.db', codec: sembastFirestoreCodec);
  var store = stringMapStoreFactory.store('event');

  await store.record('e1').put(db, {'at': Timestamp(1234, 5678)});
  await store.record('e2').put(db, {'at': Timestamp(1234, 9102)});
  await store.record('e3').put(db, <String, Object?>{}); // no timestamp

  // Ascending: missing values first.
  var finder = Finder(sortOrders: [SortOrder('at', true)]);
  var keys = (await store.find(db, finder: finder)).map((e) => e.key).toList();
  print(keys); // [e3, e1, e2]

  // Annotated json, re-importable with the same codec.
  var export = await exportDatabase(db);
  print(export);
  await db.close();

  var imported = await importDatabase(
    export,
    factory,
    'events_copy.db',
    codec: sembastFirestoreCodec,
  );
  print(await store.record('e1').get(imported));
  await imported.close();
}
```

### Adapters alone, and a custom codec

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:sembast/sembast.dart';
import 'package:sembast/utils/type_adapter.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

void main() {
  // Convert without any database involved.
  print(sembastFirestoreTimestampAdapter.encode(Timestamp(1234, 5678)));
  print(sembastFirestoreTimestampAdapter.decode({
    'seconds': 1234,
    'nanoseconds': 5678,
  }));
  print(sembastFirestoreBlobAdapter.encode(Blob(Uint8List.fromList([1, 2, 3]))));
  print(sembastFirestoreGeoPointAdapter.isType(const GeoPoint(1.1, 2.2)));

  // Firestore types AND the sembast Timestamp/Blob types, own signature.
  var myCodec = SembastCodec(
    signature: 'my_app_firestore',
    codec: json,
    jsonEncodableCodec: JsonEncodableCodec(
      adapters: [
        ...sembastFirestoreDefaultTypeAdapters,
        ...sembastDefaultTypeAdapters,
      ],
    ),
  );
  // Use it in openDatabase(path, codec: myCodec) - never mix signatures on
  // one database.
  print(myCodec.signature);
}
```
