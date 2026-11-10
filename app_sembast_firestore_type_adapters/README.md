# tekartik_app_sembast_firestore_type_adapters

Sembast type adapters to store the `Timestamp`, `Blob` and `GeoPoint` values of
[tekartik_firebase_firestore](https://github.com/tekartik/firebase_firestore.dart)
(not `cloud_firestore`) in a sembast database, and `sembastFirestoreCodec`, the
codec bundling them. Handy to keep a local copy of firestore documents.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_sembast_firestore_type_adapters:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_sembast_firestore_type_adapters
```

```dart
import 'dart:typed_data';

import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

Future<void> main() async {
  // The codec is needed at every open of this database.
  var db = await newDatabaseFactoryMemory().openDatabase(
    'cache.db',
    codec: sembastFirestoreCodec,
  );
  var store = stringMapStoreFactory.store('doc');
  await store.record('a').put(db, {
    'updated': Timestamp(1234, 5678),
    'thumbnail': Blob(Uint8List.fromList([1, 2, 3])),
    'location': const GeoPoint(48.85, 2.35),
  });
  var data = (await store.record('a').get(db))!;
  print(data['updated'] is Timestamp); // true
  await db.close();
}
```

Pure Dart, any sembast factory (io, sqflite, web, memory). See
[example/main.dart](example/main.dart).

## What to use

* `sembastFirestoreCodec`: pass it as `codec:` to `openDatabase`.
* `sembastFirestoreDefaultTypeAdapters`,
  `sembastFirestoreDefaultJsonEncodableCodec`: to build your own codec.
* `sembastFirestoreTimestampAdapter`, `sembastFirestoreBlobAdapter`,
  `sembastFirestoreGeoPointAdapter`: the adapters alone (`encode`, `decode`).

## Common pitfalls

* Open the database with the codec every time: its signature is
  `'firestore'`, a database written with it does not open without it, and a
  database written without it does not open with it (`Invalid codec
  signature` on io, sqflite and the web; the in memory
  `newDatabaseFactoryMemory()` checks nothing).
* The codec replaces sembast's default adapters: sembast's own `Timestamp`
  and `Blob` (`package:sembast/timestamp.dart`, `package:sembast/blob.dart`)
  are refused (`Invalid argument: type Timestamp not supported`). To store
  both, build a codec with
  `[...sembastFirestoreDefaultTypeAdapters, ...sembastDefaultTypeAdapters]`
  and a signature of your own.
* `DocumentReference`, `FieldValue` and `VectorValue` are not supported.

## Agent skills

[skills/tekartik-app-sembast-firestore-type-adapters-codec](skills/tekartik-app-sembast-firestore-type-adapters-codec/SKILL.md).
