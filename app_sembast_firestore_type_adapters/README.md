# tekartik_app_sembast_firestore_type_adapters

[Tekartik Firestore](https://github.com/tekartik/firebase_firestore.dart) (i.e. not cloud_firestore) type adapters for sembast

## Verioning

Follow [tekartik git versioning](https://github.com/tekartik/common.dart/blob/main/doc/tekartik_versioning.md)

## Setup

pubspec.yaml:

```yaml
dependencies:
  tekartik_app_sembast_firestore_type_adapters:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_sembast_firestore_type_adapters
    version: '>=0.1.0'
```

## Usage

```dart
import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';

DatabaseFactory factory;

var db = await factory.openDatabase('db', codec: sembastFirestoreCodec);

// You can then store firestore content data inside sembast
var store = stringMapStoreFactory.store();
var record = store.record('test');
var data = {
  'int': 1,
  'String': 'text',
  'firestoreTimestamp': Timestamp(1234, 5678),
  'firestoreBlob': Blob(Uint8List.fromList([1, 2, 3])),
  'firestoreGeoPoint': const GeoPoint(1.1, 2.2)
};
await record.add(db, data);
```
