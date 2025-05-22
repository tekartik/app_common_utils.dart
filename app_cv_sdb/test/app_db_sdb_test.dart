import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

import 'package:test/test.dart';

class DbTest extends ScvIntRecordBase {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

class DbStringTest extends ScvStringRecordBase {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

class DbString2Test extends ScvStringRecordBase {
  final value2 = CvField<int>('value2');

  @override
  List<CvField> get fields => [value2];
}

bool contentAndKeyEquals(ScvRecord? record1, ScvRecord? record2) {
  return record1?.rawRef == record2?.rawRef && record1 == record2;
}

void main() {
  disableSembastCooperator();
  group('store', () {
    late Database db;
    setUpAll(() {
      cvAddConstructors([DbTest.new, DbStringTest.new, DbString2Test.new]);
    });
    setUp(() async {
      db = await newDatabaseFactoryMemory().openDatabase('test');
    });
    tearDown(() {
      db.close();
    });
    test('toMap', () async {
      var store = scvIntStoreFactory.store<DbTest>('test');
      var record1 = store.record(1).cv();
      var record2 = store.record(2).cv();
      expect([record1, record2].toMap(), {1: record1, 2: record2});
    });
    test('ref', () async {
      var store1 = scvIntStoreFactory.store('test');
      var store2 = scvIntStoreFactory.store('test');
      expect(store1, store2);
      var record1 = store1.record(1);
      var record2 = store2.record(1);
      expect(record1, record2);
      record2 = store1.record(2);
      expect(record1, isNot(record2));
      store2 = scvIntStoreFactory.store('tes2');
      expect(store1, isNot(store2));
      record2 = store2.record(1);
      expect(record1, isNot(record2));
    });
    test('int.ref', () async {
      var store = scvIntStoreFactory.store<DbTest>('store');
      var record = store.record(1);
      expect(record, isA<ScvIntRecordRef<DbTest>>());
      var scvRecordRef = ScvIntRecordRef(store, 1);
      expect(scvRecordRef, isA<ScvIntRecordRef<DbTest>>());
      scvRecordRef = store.record(2);
      expect(scvRecordRef, isA<ScvIntRecordRef<DbTest>>());
    });
    test('string.ref', () async {
      var store = scvStringStoreFactory.store<DbStringTest>('store');
      var record = store.record('test');
      expect(record, isA<ScvStringRecordRef<DbStringTest>>());
      var scvRecordRef = ScvStringRecordRef(store, 'test');
      expect(scvRecordRef, isA<ScvStringRecordRef<DbStringTest>>());
      scvRecordRef = store.record('test2');
      expect(scvRecordRef, isA<ScvStringRecordRef<DbStringTest>>());
    });
    test('model.ref', () {
      var store = scvIntStoreFactory.store<DbTest>('test');
      var record = store.record(1);
      var scvRecord = record.cv();
      expect(scvRecord.ref, record);
      expect(scvRecord.refOrNull, record);
      scvRecord.ref = store.record(2);
      expect(scvRecord.id, 2);
      expect(scvRecord.idOrNull, 2);
      scvRecord = DbTest();
      expect(scvRecord.hasId, isFalse);
      scvRecord.ref = store.record(2);
      expect(scvRecord.id, 2);
      expect(scvRecord.hasId, isTrue);
      scvRecord.idOrNull = 3;
      expect(scvRecord.id, 3);
      scvRecord.refOrNull = null;
      expect(scvRecord.idOrNull, isNull);
      scvRecord.refOrNull = record;
      expect(scvRecord.id, 1);

      var list = [scvRecord, store.record(3).cv()];
      expect(list.ids, [1, 3]);
    });
    test('clone', () async {
      var original =
          scvIntStoreFactory.store<DbTest>('test').record(1).cv()..value.v = 2;
      var record = original.scvClone();
      expect(record, original);
      expect(record, isNot(same(original)));
      expect(record.value.v, 2);
      expect(record.id, 1);

      original = DbTest()..value.v = 3;
      record = original.scvClone();
      expect(record, original);
      expect(record, isNot(same(original)));
      expect(record.value.v, 3);
      expect(record.idOrNull, isNull);
    });
    test('cast', () async {
      var store =
          scvIntStoreFactory
              .store<DbTest>('test')
              .cast<String, DbStringTest>()
              .castV<DbStringTest>();
      var record = store.record('test').cv()..value.v = 1;
      expect(record.toMap(), {'value': 1});
      var record2 =
          store.record('test').castV<DbString2Test>().cv()..value2.v = 2;
      expect(record2.toMap(), {'value2': 2});
    });
    /*
    test('int store', () async {
      var store = intMapStoreFactory.store('test');
      var cvStore = scvIntStoreFactory.store<DbTest>('test');
      expect(cvStore, isA<ScvIntStoreRef<DbTest>>());
      var dbTest = DbTest()..value.v = 1;
      expect(dbTest.hasId, false);

      var recordRef = store.record(1);
      var scvRecordRef = cvStore.record(1);
      expect(scvRecordRef, isA<ScvIntRecordRef<DbTest>>());
      expect(scvRecordRef.key, 1);
      /*
      await store.record(1).put(db, {'value': 1});
      expect(await recordRef.get(scv), {'value': 1});
      expect(recordRef.getSync(scv), {'value': 1});
      var readDbTest = (await scvRecordRef.get(scv))!;
      expect(readDbTest, dbTest);
      expect(readDbTest.rawRef.key, 1);
      expect(readDbTest.ref.key, 1);
      expect(readDbTest.refOrNull?.key, 1);
      expect(readDbTest.idOrNull, 1);
      var writeDbTest = scvRecordRef.cv()..value.v = 2;
      await writeDbTest.put(scv);
      readDbTest = (await scvRecordRef.get(scv))!;
      expect(readDbTest, writeDbTest);
      //expect(contentAndKeyEquals(await store.findFirst(scv)), writeDbTest);

      //cvStore.*/
    });

    test('string store', () async {
      var store = stringMapStoreFactory.store('test');
      var cvStore = scvStringStoreFactory.store<DbStringTest>('test');
      expect(cvStore, isA<ScvStringStoreRef<DbStringTest>>());
      var dbTest = DbTest()..value.v = 1;
      var recordRef = store.record('1');
      var scvRecordRef = cvStore.record('1');
      expect(scvRecordRef, isA<ScvStringRecordRef<DbStringTest>>());
      /*
      await store.record('1').put(scv, {'value': 1});
      expect(await recordRef.get(scv), {'value': 1});
      expect(await recordRef.exists(scv), true);
      var readDbTest = await scvRecordRef.get(scv);
      expect(readDbTest, dbTest);
      expect(readDbTest!.rawRef.key, '1');
      var writeDbTest = scvRecordRef.cv()..value.v = 2;
      expect(writeDbTest.ref, scvRecordRef);
      await writeDbTest.put(scv);
      readDbTest = await scvRecordRef.get(scv);
      expect(readDbTest, writeDbTest);
      //expect(contentAndKeyEquals(await store.findFirst(scv)), writeDbTest);

      //cvStore.*/
    });*/
  });
}
