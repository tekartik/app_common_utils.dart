import 'package:sembast/sembast.dart' show disableSembastCooperator;
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

import 'package:test/test.dart';

import 'app_cv_sdb_test.dart';

class DbTestWithId extends ScvIntRecordBase {
  final value = CvField<int>('value');
  final recId = CvField<int>('id');

  @override
  List<CvField> get fields => [recId, value];
}

final dbIntTestWithIdStore = scvIntStoreFactory.store<DbTestWithId>(
  'int_test_with_id',
);

class DbStringTestWithId extends ScvStringRecordBase {
  final value = CvField<int>('value');
  final recId = CvField<String>('id');
  @override
  List<CvField> get fields => [recId, value];
}

final dbStringTestWithIdStore = scvStringStoreFactory.store<DbStringTestWithId>(
  'string_test_with_id',
);
void main() {
  disableSembastCooperator();
  group('db_simple', () {
    late SdbDatabase db;
    setUpAll(() {
      cvAddConstructors([
        DbTest.new,
        DbStringTest.new,
        DbString2Test.new,
        DbStringTestWithId.new,
        DbTestWithId.new,
      ]);
    });
    setUp(() async {
      var factory = newSdbFactoryMemory();
      db = await factory.openDatabase(
        'test',
        version: 1,
        onVersionChange: (e) {
          if (e.oldVersion < 1) {
            var db = e.db;
            db.scvCreateStore(dbIntTestStore);
            db.scvCreateStore(dbStringTestStore);
          }
        },
      );
    });
    tearDown(() {
      db.close();
    });

    test('int store', () async {
      var store = SdbStoreRef<int, Model>(dbIntTestStore.name);
      var cvStore = dbIntTestStore;
      expect(cvStore, isA<ScvIntStoreRef<DbTest>>());
      var dbTest = DbTest()..value.v = 1;
      expect(dbTest.hasId, false);

      var recordRef = store.record(1);
      var scvRecordRef = cvStore.record(1);
      expect(scvRecordRef, isA<ScvIntRecordRef<DbTest>>());
      expect(scvRecordRef.key, 1);

      await store.record(1).put(db, {'value': 1});
      expect(await recordRef.getValue(db), {'value': 1});
      var readDbTest = (await scvRecordRef.get(db))!;
      expect(readDbTest, dbTest);
      expect(readDbTest.rawRef.key, 1);
      expect(readDbTest.ref.key, 1);
      expect(readDbTest.refOrNull?.key, 1);
      expect(readDbTest.idOrNull, 1);
      var writeDbTest = scvRecordRef.cv()..value.v = 2;
      await writeDbTest.put(db);
      readDbTest = (await scvRecordRef.get(db))!;
      expect(readDbTest, writeDbTest);
    });

    test('string store', () async {
      var store = SdbStoreRef<String, Model>(dbStringTestStore.name);
      var cvStore = dbStringTestStore;
      expect(cvStore, isA<ScvStringStoreRef<DbStringTest>>());
      var dbTest = DbTest()..value.v = 1;
      var recordRef = store.record('1');
      var scvRecordRef = cvStore.record('1');
      expect(scvRecordRef, isA<ScvStringRecordRef<DbStringTest>>());

      await store.record('1').put(db, {'value': 1});
      expect(await recordRef.getValue(db), {'value': 1});
      expect(await recordRef.exists(db), true);
      var readDbTest = await scvRecordRef.get(db);
      expect(readDbTest, dbTest);
      expect(readDbTest!.rawRef.key, '1');
      var writeDbTest = scvRecordRef.cv()..value.v = 2;
      expect(writeDbTest.ref, scvRecordRef);
      await writeDbTest.put(db);
      readDbTest = await scvRecordRef.get(db);
      expect(readDbTest, writeDbTest);
    });

    test('update', () async {
      var store = dbIntTestStore;
      var record = store.record(1).cv()..value.v = 1;
      expect(await record.update(db), false);
      expect(await record.delete(db), false);
      expect(await record.add(db), true);
      expect(await record.add(db), false);
      expect(await record.update(db), true);
      expect(await record.delete(db), true);
      expect(await record.delete(db), false);
    });

    test('store.add/find/delete', () async {
      var store = dbIntTestStore;
      var record = DbTest()..value.v = 1;
      record = await store.add(db, record);
      expect(record.idOrNull, isNotNull);
      expect(record.ref.store, store);
      expect(
        await store.findRecords(db, filter: SdbFilter.equals('value', 1)),
        [record],
      );
      expect(
        await store.findRecord(db, filter: SdbFilter.equals('value', 1)),
        record,
      );
      expect(
        await store.findRecords(db, filter: SdbFilter.equals('value', 0)),
        isEmpty,
      );

      await store.delete(
        db,
        boundaries: SdbBoundaries.lowerValue(record.id + 1),
      );
      expect(await store.count(db), 1);
      await store.delete(db, boundaries: SdbBoundaries.lowerValue(record.id));
      expect(await store.count(db), 0);
    });
    test('document.add', () async {
      var store = dbStringTestStore;
      var record = store.record('my_key').cv()..value.v = 1;
      expect(await record.add(db), isTrue);
      expect(record.idOrNull, isNotNull);
      expect(record.ref.store, store);
    });
    test('documentRef.add/delete', () async {
      var store = dbStringTestStore;
      var recordRef = store.record('my_key');
      var record = DbStringTest()..value.v = 1;
      var id = await recordRef.add(db, record);

      expect(record.idOrNull, isNull);
      expect(id, isNotNull);

      await recordRef.delete(db);
      expect(await recordRef.exists(db), false);
    });

    test('documentRef.put', () async {
      var store = dbStringTestStore;
      var record = DbStringTest()..value.v = 1;
      var docRef = store.record('test');
      expect(await docRef.exists(db), isFalse);
      var putRecord = await docRef.put(db, record);
      expect(putRecord.ref, docRef);
      expect(await docRef.exists(db), isTrue);
      var doc = docRef.cv();
      expect(await docRef.get(db), record);
      doc.value.v = 2;
      await docRef.put(db, doc);
      expect(await docRef.get(db), doc);
    });

    test('document.put', () async {
      var store = dbStringTestStore;

      var docRef = store.record('test');
      var record = docRef.cv()..value.v = 1;
      expect(await docRef.exists(db), isFalse);

      await record.put(db);
      record = docRef.cv()..value.v = 2;
      await record.put(db);
      expect(record.value.v, 2);
    });
  });
  group('db_keypath_autoincrement', () {
    late SdbDatabase db;
    setUpAll(() {
      cvAddConstructors([
        DbTestWithId.new,
        DbStringTest.new,
        DbString2Test.new,
      ]);
    });
    setUp(() async {
      var factory = newSdbFactoryMemory();
      db = await factory.openDatabase(
        'test',
        version: 1,
        onVersionChange: (e) {
          if (e.oldVersion < 1) {
            var db = e.db;
            db.scvCreateStore(
              dbIntTestWithIdStore,
              autoIncrement: true,
              keyPath: 'id',
            );
            db.scvCreateStore(dbStringTestWithIdStore, keyPath: 'id');
          }
        },
      );
    });
    tearDown(() {
      db.close();
    });

    test('int with id store', () async {
      var dbStore = dbIntTestWithIdStore;
      var dbRecord = DbTestWithId()..value.v = 1234;
      var addedRecord = await dbStore.add(db, dbRecord);
      expect(addedRecord.value.v, 1234);
      var id = addedRecord.id;
      expect(addedRecord.idOrNull, isNotNull);
      expect(addedRecord.ref.store, dbStore);
      expect(addedRecord.recId.v, id);
      expect(dbRecord.idOrNull, isNull);
      expect(dbRecord.recId.v, isNull);
      var readRecord = await dbStore.record(addedRecord.id).get(db);
      expect(contentAndKeyEquals(addedRecord, readRecord), isNotNull);
    });

    test('string with id store', () async {
      var dbStore = dbStringTestWithIdStore;
      var dbRecord =
          DbStringTestWithId()
            ..value.v = 1234
            ..recId.v = 'my_key';
      var addedRecord = await dbStore.add(db, dbRecord);
      expect(addedRecord.value.v, 1234);
      var id = addedRecord.id;
      expect(id, 'my_key');
      expect(addedRecord.idOrNull, id);
      expect(addedRecord.ref.store, dbStore);
      expect(addedRecord.recId.v, id);
      expect(dbRecord.idOrNull, isNull);

      var readRecord = await dbStore.record(addedRecord.id).get(db);
      expect(contentAndKeyEquals(addedRecord, readRecord), isNotNull);
    });
  });
  group('index', () {
    late SdbDatabase db;
    setUpAll(() {
      cvAddConstructors([DbTest.new, DbStringTest.new, DbString2Test.new]);
    });
    setUp(() async {
      var factory = newSdbFactoryMemory();
      db = await factory.openDatabase(
        'test',
        version: 1,
        onVersionChange: (e) {
          if (e.oldVersion < 1) {
            var db = e.db;

            var store = db.scvCreateStore(dbIntTestStore);
            store.createIndex(dbIntTestIndex, 'value');
          }
        },
      );
    });
    tearDown(() {
      db.close();
    });

    test('index1', () async {
      var dbStore = dbIntTestStore;
      var dbRecordRef = dbStore.record(1);
      var record = await dbRecordRef.add(db, DbTest()..value.v = 1234);
      var ref = dbIntTestIndex.record(1234);
      var indexRecord = (await ref.get(db))!;
      expect(indexRecord.record, record);
      expect(indexRecord.key, record.id);
      expect(await dbIntTestIndex.record(4321).get(db), isNull);
      expect(
        await dbIntTestIndex.findRecords(
          db,
          boundaries: SdbBoundaries.lower(dbIntTestIndex.lowerBoundary(1235)),
        ),
        isEmpty,
      );
      expect(
        (await dbIntTestIndex.findRecord(
          db,
          boundaries: SdbBoundaries.lower(dbIntTestIndex.lowerBoundary(1234)),
        ))!.record,
        record,
      );
      expect(
        (await dbIntTestIndex.findRecordKey(
          db,
          boundaries: SdbBoundaries.lowerValue(123),
        ))!.key,
        record.id,
      );
    });
  });
}
