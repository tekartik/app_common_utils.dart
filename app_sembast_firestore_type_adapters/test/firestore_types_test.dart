import 'dart:typed_data';

import 'package:sembast/sembast_memory.dart';
import 'package:sembast/utils/sembast_import_export.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:test/test.dart';

void main() {
  group('sembast', () {
    var factory = databaseFactoryMemoryFs;
    test('simple', () async {
      var store = stringMapStoreFactory.store();
      var db = await factory.openDatabase('db', codec: sembastFirestoreCodec);
      var record = store.record('test');
      var data = {
        'int': 1,
        'String': 'text',
        'firestoreTimestamp': Timestamp(1234, 5678),
        'firestoreBlob': Blob(Uint8List.fromList([1, 2, 3])),
        'firestoreGeoPoint': const GeoPoint(1.1, 2.2)
      };
      await record.add(db, data);
      expect(await record.get(db), data);
      await db.close();

      // reopen and check content
      db = await factory.openDatabase('db', codec: sembastFirestoreCodec);
      expect(await record.get(db), data);

      var export = {
        'sembast_export': 1,
        'version': 1,
        'stores': [
          {
            'name': '_main',
            'keys': ['test'],
            'values': [
              {
                'int': 1,
                'String': 'text',
                'firestoreTimestamp': {
                  '@FirestoreTimestamp': {'seconds': 1234, 'nanoseconds': 5678}
                },
                'firestoreBlob': {'@FirestoreBlob': 'AQID'},
                'firestoreGeoPoint': {
                  '@FirestoreGeoPoint': {'latitude': 1.1, 'longitude': 2.2}
                }
              }
            ]
          }
        ]
      };
      expect(await exportDatabase(db), export);
      await db.close();

      db = await importDatabase(export, factory, 'imported',
          codec: sembastFirestoreCodec);
      expect(await record.get(db), data);
      await db.close();
    });
  });
}
