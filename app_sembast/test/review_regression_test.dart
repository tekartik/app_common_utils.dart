import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_sembast/unique_index.dart';
import 'package:test/test.dart';

void main() {
  group('unique index review regression', () {
    late Database db;
    var store = intMapStoreFactory.store('store');
    var index = store.index<int>('key');
    setUp(() async {
      db = await newDatabaseFactoryMemory().openDatabase('review.db');
    });
    tearDown(() async {
      await db.close();
    });

    // put through the index on an existing record used to write the value
    // without the index field: the record left the index.
    test('put existing record keeps the index key', () async {
      var dbIndex = db.index(index);
      var pk = (await dbIndex.record(6).add({'v': 1}))!;
      expect(await dbIndex.record(6).put({'v': 2}), {'key': 6, 'v': 2});
      expect(await store.record(pk).get(db), {'key': 6, 'v': 2});
      expect((await dbIndex.record(6).getSnapshot())!.key, pk);

      // An explicit index field still moves the record.
      expect(await dbIndex.record(6).put({'key': 7, 'v': 3}), {
        'key': 7,
        'v': 3,
      });
      expect(await dbIndex.record(6).getSnapshot(), isNull);
      expect((await dbIndex.record(7).getSnapshot())!.key, pk);
    }, timeout: const Timeout(Duration(seconds: 10)));

    // A conflict refused by throwOnConflict used to remove the current key of
    // the record from the index (the write itself is rolled back).
    test('refused conflict keeps the index', () async {
      var dbIndex = db.index(index, throwOnConflict: true);
      await store.record(1).put(db, {'key': 2});
      await store.record(2).put(db, {'key': 3});
      await expectLater(
        store.record(2).put(db, {'key': 2}),
        throwsA(isA<StateError>()),
      );
      expect(await store.record(2).get(db), {'key': 3});
      expect((await dbIndex.record(3).getSnapshot())!.key, 2);
      expect((await dbIndex.record(2).getSnapshot())!.key, 1);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('refused conflict in a batch keeps the index', () async {
      var dbIndex = db.index(index, throwOnConflict: true);
      await store.record(1).put(db, {'key': 2});
      await expectLater(
        store.records([10, 11]).put(db, [
          {'key': 10},
          {'key': 2},
        ]),
        throwsA(isA<StateError>()),
      );
      expect(await store.record(10).get(db), isNull);
      expect(await dbIndex.record(10).getSnapshot(), isNull);
      // Not seen as a conflict now.
      await store.record(12).put(db, {'key': 10});
      expect((await dbIndex.record(10).getSnapshot())!.key, 12);
      expect((await dbIndex.record(2).getSnapshot())!.key, 1);
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
