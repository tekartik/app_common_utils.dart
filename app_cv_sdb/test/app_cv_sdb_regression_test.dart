import 'package:sembast/sembast.dart' show disableSembastCooperator;
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:test/test.dart';

import 'app_cv_sdb_db_test.dart';
import 'app_cv_sdb_test.dart';

final _keyPathStore = scvIntStoreFactory.store<DbTestWithId>('key_path');

void main() {
  disableSembastCooperator();
  cvAddConstructors([
    DbTest.new,
    DbStringTest.new,
    DbTestWithId.new,
    DbUserProject.new,
  ]);
  late SdbDatabase db;
  setUp(() async {
    db = await newSdbFactoryMemory().openDatabase(
      'regression',
      options: SdbOpenDatabaseOptions(
        version: 1,
        schema: SdbDatabaseSchema(
          stores: [
            dbIntTestStore.schema(),
            dbStringTestStore.schema(),
            _keyPathStore.schema(
              keyPath: SdbKeyPath.single('id'),
              autoIncrement: true,
            ),
            userProjectStore.schema(indexes: [userProjectIndexSchema]),
          ],
        ),
      ),
    );
  });
  tearDown(() async {
    await db.close();
  });

  group('record.add keeps its key', () {
    test('string', () async {
      var record = dbStringTestStore.record('my_key').cv()..value.v = 1;
      expect(await record.add(db), isTrue);
      expect(record.id, 'my_key');
      expect(await dbStringTestStore.record('my_key').get(db), record);
      expect(await dbStringTestStore.count(db), 1);
    });
    test('int', () async {
      var record = dbIntTestStore.record(5).cv()..value.v = 1;
      expect(await record.add(db), isTrue);
      expect(record.id, 5);
      expect(await dbIntTestStore.record(5).get(db), record);
      expect(await dbIntTestStore.record(1).exists(db), isFalse);
    });
  });

  group('key path store with explicit keys', () {
    test('ref.put', () async {
      var value = DbTestWithId()..value.v = 1;
      var put = await _keyPathStore.record(3).put(db, value);
      expect(put.id, 3);
      expect(put.recId.v, 3);
      expect((await _keyPathStore.record(3).get(db))!.value.v, 1);
    });
    test('ref.add', () async {
      var added = await _keyPathStore
          .record(7)
          .add(db, DbTestWithId()..value.v = 1);
      expect(added.id, 7);
      expect(added.recId.v, 7);
      expect(await _keyPathStore.record(7).exists(db), isTrue);
    });
    test('record.put', () async {
      var record = _keyPathStore.record(4).cv()..value.v = 1;
      await record.put(db);
      expect(record.recId.v, 4);
      expect((await _keyPathStore.record(4).get(db))!.value.v, 1);
    });
    test('record.add', () async {
      var record = _keyPathStore.record(8).cv()..value.v = 1;
      expect(await record.add(db), isTrue);
      expect(record.id, 8);
      expect(record.recId.v, 8);
      expect(await _keyPathStore.record(8).exists(db), isTrue);
      expect(await record.add(db), isFalse);
    });
    test('record.update', () async {
      var record = _keyPathStore.record(9).cv()..value.v = 1;
      await record.put(db);
      record.value.v = 2;
      expect(await record.update(db), isTrue);
      expect((await _keyPathStore.record(9).get(db))!.value.v, 2);
    });
  });

  test('index2 and index3 boundaries', () async {
    await userProjectStore
        .record(1)
        .put(
          db,
          DbUserProject()
            ..userId.v = 1
            ..projectId.v = 'a',
        );
    await userProjectStore
        .record(2)
        .put(
          db,
          DbUserProject()
            ..userId.v = 2
            ..projectId.v = 'a',
        );
    var records = await userProjectIndex.findRecords(
      db,
      boundaries: SdbBoundaries(
        userProjectIndex.lowerBoundary(1, 'a'),
        userProjectIndex.upperBoundary(2, 'a'),
      ),
    );
    expect(records.map((record) => record.record.id), [1]);

    var index3 = userProjectStore.index3<int, String, int>('index3');
    var lower = index3.lowerBoundary(1, 'a', 2);
    expect(lower.value, (1, 'a', 2));
    expect(index3.upperBoundary(1, 'a', 2).value, (1, 'a', 2));
  });
}
