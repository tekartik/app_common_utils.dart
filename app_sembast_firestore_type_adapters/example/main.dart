// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:sembast/sembast_memory.dart';
import 'package:sembast/utils/sembast_import_export.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

Future<void> main() async {
  var factory = newDatabaseFactoryMemory();
  // The codec is needed at every open of this database.
  var db = await factory.openDatabase('cache.db', codec: sembastFirestoreCodec);
  var store = stringMapStoreFactory.store('doc');

  await store.record('a').put(db, {
    'updated': Timestamp(1234, 5678),
    'thumbnail': Blob(Uint8List.fromList([1, 2, 3])),
    'location': const GeoPoint(48.85, 2.35),
  });
  await store.record('b').put(db, {'updated': Timestamp(5, 0)});

  // The firestore types come back.
  var data = (await store.record('a').get(db))!;
  print((data['updated'] as Timestamp).seconds); // 1234
  print((data['thumbnail'] as Blob).data); // [1, 2, 3]
  print((data['location'] as GeoPoint).latitude); // 48.85

  // Timestamps sort chronologically.
  var keys = (await store.find(
    db,
    finder: Finder(sortOrders: [SortOrder('updated')]),
  )).map((record) => record.key).toList();
  print(keys); // [b, a]

  // Stored form: annotated json.
  print((await exportDatabase(db))['stores']);
  await db.close();
}
