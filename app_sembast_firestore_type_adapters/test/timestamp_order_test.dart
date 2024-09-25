import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/type_adapters.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:test/test.dart';

Future<List<String>> getSnapshotKeys(
    QueryRef<String, dynamic> queryRef, DatabaseClient client) async {
  return (await queryRef.getSnapshots(client))
      .map((e) => e.key)
      .toList(growable: false);
}

void main() {
  group('timestamp', () {
    var factory = databaseFactoryMemoryFs;
    test('order', () async {
      var store = stringMapStoreFactory.store();
      var db = await factory.openDatabase('db', codec: sembastFirestoreCodec);
      var record1 = store.record('test1');
      var record2 = store.record('test2');
      var record3 = store.record('test3');
      var record4 = store.record('test4');
      // Middle date
      var data1 = {
        'timestamp': Timestamp(1234, 5678),
      };
      // Most recent
      var data2 = {
        'timestamp': Timestamp(1234, 9102),
      };
      // Null date, listed first in ascending order, last in descending order
      var data3 = <String, dynamic>{};
      // First in ascending order
      var data4 = {
        'timestamp': Timestamp(5, 0),
      };
      await record1.add(db, data1);
      await record2.add(db, data2);
      await record3.add(db, data3);
      await record4.add(db, data4);

      Future checkContent() async {
        var finder = Finder(sortOrders: [SortOrder('timestamp', true)]);
        var reverseFinder = Finder(sortOrders: [SortOrder('timestamp', false)]);
        expect((await getSnapshotKeys(store.query(finder: finder), db)),
            ['test3', 'test4', 'test1', 'test2']);
        expect((await getSnapshotKeys(store.query(finder: reverseFinder), db)),
            ['test2', 'test1', 'test4', 'test3']);

        expect((await store.findFirst(db, finder: finder))!.key, 'test3');
        expect(
            (await store.findFirst(db, finder: reverseFinder))!.key, 'test2');
      }

      await checkContent();
      await db.close();

      // reopen and check content
      db = await factory.openDatabase('db', codec: sembastFirestoreCodec);
      await checkContent();

      await db.close();
    });
  });
}
