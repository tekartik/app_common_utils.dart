import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast/unique_index.dart';
import 'package:test/test.dart';

void main() {
  group('any', () {
    var path = '.dart_tool/sembast_exp/unique_index.sdb';
    late Database db;
    setUp(() async {
      await databaseFactoryMemory.deleteDatabase(path);
      db = await databaseFactoryMemory.openDatabase(path);
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
      db = await databaseFactoryMemory.openDatabase(path);
      dbIndex = db.index(index);

      expect((await dbIndex.record(2).getSnapshot())!.key, 1);
    });

    test('index throw', () async {
      var store = intMapStoreFactory.store('store');
      var index = store.index<int>('key');

      /// Create a database index.
      var dbIndex = db.index(index, throwOnConflict: true);

      await store.record(1).put(db, {'key': 2});

      try {
        // Should throw
        await store.record(2).put(db, {'key': 2});
        fail('should fail');
      } on StateError catch (_) {}
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
      db = await databaseFactoryMemory.openDatabase(path);

      try {
        dbIndex = db.index(index, throwOnConflict: true);
        await dbIndex.record(2).getSnapshot();
        fail('should fail');
      } on StateError catch (_) {}
    });

    test('index add/change/remove', () async {
      var store = intMapStoreFactory.store('store');
      var index = store.index<int>('key');

      /// Create a database index.
      var dbIndex = db.index(index);

      await store.record(1).put(db, {'key': 2});
      expect((await dbIndex.record(2).getSnapshot())!.key, 1);
      await store.record(1).put(db, {'key': 3});
      expect((await dbIndex.record(3).getSnapshot())!.key, 1);
      expect(await dbIndex.record(2).getSnapshot(), isNull);
      await store.record(1).delete(db);
      expect(await dbIndex.record(3).getSnapshot(), isNull);
    });

    test('index 2 keys', () async {
      var store = intMapStoreFactory.store('store');
      var index = store.index<int>('key');

      /// Create a database index.
      var dbIndex = db.index(index);

      await store.record(1).put(db, {'key': 2});
      await store.record(2).put(db, {'key': 3});
      expect((await dbIndex.record(2).getSnapshot())!.key, 1);
      expect((await dbIndex.record(3).getSnapshot())!.key, 2);
      await store.record(1).put(db, {'key': 3});
      expect(await dbIndex.record(2).getSnapshot(), isNull);
      expect((await dbIndex.record(3).getSnapshot())!.key, 1);
      await store.record(2).put(db, {'key': 2});
      expect((await dbIndex.record(2).getSnapshot())!.key, 2);
      expect((await dbIndex.record(3).getSnapshot())!.key, 1);
    });

    test('index dispose keys', () async {
      var store = intMapStoreFactory.store('store');
      var index = store.index<int>('key');

      /// Create a database index.
      var dbIndex = db.index(index);

      await store.record(1).put(db, {'key': 2});
      dbIndex.dispose();
      await store.record(2).put(db, {'key': 3});
      expect(await dbIndex.record(2).getSnapshot(), isNull);
      expect(await dbIndex.record(3).getSnapshot(), isNull);
    });
  });
}
