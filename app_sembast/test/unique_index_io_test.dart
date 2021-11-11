@TestOn('vm')
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_app_sembast/unique_index.dart';
import 'package:test/test.dart';

void main() {
  group('any', () {
    var path = '.dart_tool/sembast_exp/unique_index.sdb';
    late Database db;
    setUp(() async {
      await databaseFactoryIo.deleteDatabase(path);
      db = await databaseFactoryIo.openDatabase(path);
    });
    tearDown(() async {
      await db.close();
    });
    test('index simple close and open', () async {
      var store = intMapStoreFactory.store('store');
      var index = store.index<int>('key');

      /// Create a database index.
      var dbIndex = db.index(index);

      await store.record(1).put(db, {'key': 2});
      expect((await dbIndex.record(2).getSnapshot())!.key, 1);
      await db.transaction((transaction) async {
        expect(
            (await dbIndex.transactionRecord(transaction, 2).getSnapshot())!
                .key,
            1);
      });

      await db.close();
      db = await databaseFactoryIo.openDatabase(path);
      dbIndex = db.index(index);

      expect((await dbIndex.record(2).getSnapshot())!.key, 1);
    });

    test('index create duplicates throw', () async {
      var store = intMapStoreFactory.store('store');
      var index = store.index<int>('key');

      /// Create a database index.
      var dbIndex = db.index(index);

      await store.record(1).put(db, {'key': 2});
      await store.record(2).put(db, {'key': 2});
      expect((await dbIndex.record(2).getSnapshot())!.key, 2);

      await db.close();
      db = await databaseFactoryIo.openDatabase(path);

      try {
        dbIndex = db.index(index, throwOnConflict: true);
        await dbIndex.record(2).getSnapshot();
        fail('should fail');
      } on StateError catch (_) {}
    });
  });
}
