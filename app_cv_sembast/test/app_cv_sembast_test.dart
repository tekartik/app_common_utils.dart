import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

class DbTest extends DbIntRecordBase {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

class DbStringTest extends DbStringRecordBase {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

bool contentAndKeyEquals(DbRecord? record1, DbRecord? record2) {
  return record1?.rawRef == record2?.rawRef && record1 == record2;
}

void main() {
  disableSembastCooperator();
  group('store', () {
    late Database db;
    setUpAll(() {
      cvAddBuilder<DbTest>((_) => DbTest());
      cvAddBuilder<DbStringTest>((_) => DbStringTest());
    });
    setUp(() async {
      db = await newDatabaseFactoryMemory().openDatabase('test');
    });
    tearDown(() {
      db.close();
    });
    test('int store', () async {
      var store = intMapStoreFactory.store('test');
      var cvStore = cvIntRecordFactory.store<DbTest>('test');
      var dbTest = DbTest()..value.v = 1;
      expect(dbTest.hasId, false);
      var recordRef = store.record(1);
      var cvRecordRef = cvStore.record(1);
      await store.record(1).put(db, {'value': 1});
      expect(await recordRef.get(db), {'value': 1});
      var readDbTest = await cvRecordRef.get(db);
      expect(readDbTest, dbTest);
      expect(readDbTest!.rawRef.key, 1);
      var writeDbTest = cvRecordRef.cv()..value.v = 2;
      await writeDbTest.put(db);
      readDbTest = await cvRecordRef.get(db);
      expect(readDbTest, writeDbTest);
      //expect(contentAndKeyEquals(await store.findFirst(db)), writeDbTest);

      //cvStore.
    });

    test('string store', () async {
      var store = stringMapStoreFactory.store('test');
      var cvStore = cvStringRecordFactory.store<DbStringTest>('test');
      var dbTest = DbTest()..value.v = 1;
      var recordRef = store.record('1');
      var cvRecordRef = cvStore.record('1');
      await store.record('1').put(db, {'value': 1});
      expect(await recordRef.get(db), {'value': 1});
      var readDbTest = await cvRecordRef.get(db);
      expect(readDbTest, dbTest);
      expect(readDbTest!.rawRef.key, '1');
      var writeDbTest = cvRecordRef.cv()..value.v = 2;
      await writeDbTest.put(db);
      readDbTest = await cvRecordRef.get(db);
      expect(readDbTest, writeDbTest);
      //expect(contentAndKeyEquals(await store.findFirst(db)), writeDbTest);

      //cvStore.
    });

    test('update', () async {
      var cvStore = cvStringRecordFactory.store<DbStringTest>('test');
      var cvRecord = cvStore.record('1').cv()..value.v = 1;
      expect(await cvRecord.update(db), false);
      expect(await cvRecord.delete(db), false);
      expect(await cvRecord.add(db), true);
      expect(await cvRecord.add(db), false);
      expect(await cvRecord.update(db), true);
      expect(await cvRecord.delete(db), true);
      expect(await cvRecord.delete(db), false);
    });

    test('onRecord', () async {
      var cvStore = cvIntRecordFactory.store<DbTest>('test');
      var cvRecordRef = cvStore.record(1); //
      Future done() async {
        await cvRecordRef
            .onRecord(db)
            .firstWhere((record) => (record?.value.v ?? 0) > 2);
      }

      Future<void> doneWithTimeOut() async {
        await done().timeout(Duration(milliseconds: 10));
      }

      try {
        await doneWithTimeOut();
        fail('should fail');
      } on TimeoutException catch (_) {
        print(_);
      }

      await (cvRecordRef.cv()..value.v = 1).put(db);
      try {
        await doneWithTimeOut();
        fail('should fail');
      } on TimeoutException catch (_) {
        print(_);
      }

      await (cvRecordRef.cv()..value.v = 3).put(db);
      await done();

      await (cvRecordRef.cv()..value.v = 1).put(db);
      try {
        await doneWithTimeOut();
        fail('should fail');
      } on TimeoutException catch (_) {
        print(_);
      }

      var doneFuture = done();
      Future<void>.delayed(Duration(milliseconds: 2)).then((_) async {
        await (cvRecordRef.cv()..value.v = 3).put(db);
      }).unawait();
      await doneFuture;
    });
  });
}
