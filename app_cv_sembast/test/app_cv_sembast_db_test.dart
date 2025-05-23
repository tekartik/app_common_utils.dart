import 'package:sembast/sembast_memory.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

import 'app_cv_sembast_test.dart';

void main() {
  disableSembastCooperator();
  group('db', () {
    setUpAll(() {
      cvAddConstructors([DbTest.new, DbStringTest.new, DbString2Test.new]);
    });

    late Database db;
    setUp(() async {
      db = await newDatabaseFactoryMemory().openDatabase('test');
    });
    tearDown(() {
      db.close();
    });

    test('int store', () async {
      var store = intMapStoreFactory.store('test');
      var cvStore = dbIntStoreFactory.store<DbTest>('test');
      expect(cvStore, isA<DbIntStoreRef<DbTest>>());
      var dbTest = DbTest()..value.v = 1;
      expect(dbTest.hasId, false);
      var recordRef = store.record(1);
      var dbRecordRef = cvStore.record(1);
      expect(dbRecordRef, isA<DbIntRecordRef<DbTest>>());
      expect(dbRecordRef.key, 1);
      await store.record(1).put(db, {'value': 1});
      expect(await recordRef.get(db), {'value': 1});
      expect(recordRef.getSync(db), {'value': 1});
      var readDbTest = (await dbRecordRef.get(db))!;
      expect(readDbTest, dbTest);
      expect(readDbTest.rawRef.key, 1);
      expect(readDbTest.ref.key, 1);
      expect(readDbTest.refOrNull?.key, 1);
      expect(readDbTest.idOrNull, 1);
      var writeDbTest = dbRecordRef.cv()..value.v = 2;
      await writeDbTest.put(db);
      readDbTest = (await dbRecordRef.get(db))!;
      expect(readDbTest, writeDbTest);
      //expect(contentAndKeyEquals(await store.findFirst(db)), writeDbTest);

      //cvStore.
    });

    test('string store', () async {
      var store = stringMapStoreFactory.store('test');
      var cvStore = dbStringStoreFactory.store<DbStringTest>('test');
      expect(cvStore, isA<DbStringStoreRef<DbStringTest>>());
      var dbTest = DbTest()..value.v = 1;
      var recordRef = store.record('1');
      var dbRecordRef = cvStore.record('1');
      expect(dbRecordRef, isA<DbStringRecordRef<DbStringTest>>());
      await store.record('1').put(db, {'value': 1});
      expect(await recordRef.get(db), {'value': 1});
      expect(await recordRef.exists(db), true);
      var readDbTest = await dbRecordRef.get(db);
      expect(readDbTest, dbTest);
      expect(readDbTest!.rawRef.key, '1');
      var writeDbTest = dbRecordRef.cv()..value.v = 2;
      expect(writeDbTest.ref, dbRecordRef);
      await writeDbTest.put(db);
      readDbTest = await dbRecordRef.get(db);
      expect(readDbTest, writeDbTest);
      //expect(contentAndKeyEquals(await store.findFirst(db)), writeDbTest);

      //cvStore.
    });

    test('update', () async {
      var cvStore = dbStringStoreFactory.store<DbStringTest>('test');
      var cvRecord = cvStore.record('1').cv()..value.v = 1;
      expect(await cvRecord.update(db), false);
      expect(await cvRecord.delete(db), false);
      expect(await cvRecord.add(db), true);
      expect(await cvRecord.add(db), false);
      expect(await cvRecord.update(db), true);
      expect(await cvRecord.delete(db), true);
      expect(await cvRecord.delete(db), false);
    });
    test('store.add', () async {
      var cvStore = dbStringStoreFactory.store<DbStringTest>('test');
      var record = DbStringTest()..value.v = 1;
      record = await cvStore.add(db, record);
      expect(record.idOrNull, isNotNull);
      expect(record.ref.store, cvStore);
    });
    test('documentRef.add', () async {
      var cvStore = dbStringStoreFactory.store<DbStringTest>('test');
      var recordRef = cvStore.record('my_key');
      var record = DbStringTest()..value.v = 1;
      var id = await recordRef.add(db, record);

      expect(record.idOrNull, isNull);
      expect(id, isNotNull);
      await recordRef.delete(db);
      expect(await recordRef.exists(db), false);
    });
    test('document.add', () async {
      var cvStore = dbStringStoreFactory.store<DbStringTest>('test');
      var record = cvStore.record('my_key').cv()..value.v = 1;
      expect(await record.add(db), isTrue);
      expect(record.idOrNull, isNotNull);
      expect(record.ref.store, cvStore);
    });

    test('documentRef.put', () async {
      var cvStore = dbStringStoreFactory.store<DbStringTest>('test');
      var record = DbStringTest()..value.v = 1;
      var docRef = cvStore.record('test');
      expect(await docRef.exists(db), isFalse);
      expect(docRef.existsSync(db), isFalse);
      var putRecord = await docRef.put(db, record);
      expect(putRecord.ref, docRef);
      expect(await docRef.exists(db), isTrue);
      expect(docRef.existsSync(db), isTrue);
      var doc = docRef.cv();
      expect(await docRef.get(db), record);
      doc.value.v = 2;
      await docRef.put(db, doc);
      expect(await docRef.get(db), doc);
    });
    test('document.put', () async {
      var cvStore = dbStringStoreFactory.store<DbString2Test>('test2');

      var docRef = cvStore.record('test');
      var record = docRef.cv()..value.v = 1;
      expect(await docRef.exists(db), isFalse);
      expect(docRef.existsSync(db), isFalse);
      await record.put(db);
      record = docRef.cv()..value2.v = 2;
      expect(record.value.v, isNull);
      await record.put(db, merge: true);
      expect(record.value.v, 1);
      expect(record.value2.v, 2);
    });

    test('onRecord', () async {
      var cvStore = dbIntStoreFactory.store<DbTest>('test');
      var dbRecordRef = cvStore.record(1); //
      Future done() async {
        await dbRecordRef
            .onRecord(db)
            .firstWhere((record) => (record?.value.v ?? 0) > 2);
      }

      Future<void> doneWithTimeOut() async {
        await done().timeout(const Duration(milliseconds: 10));
      }

      try {
        await doneWithTimeOut();
        fail('should fail');
      } on TimeoutException catch (_) {
        // print(_);
      }

      await (dbRecordRef.cv()..value.v = 1).put(db);
      try {
        await doneWithTimeOut();
        fail('should fail');
      } on TimeoutException catch (_) {
        // print(_);
      }

      await (dbRecordRef.cv()..value.v = 3).put(db);
      await done();

      await (dbRecordRef.cv()..value.v = 1).put(db);
      try {
        await doneWithTimeOut();
        fail('should fail');
      } on TimeoutException catch (_) {
        // print(_);
      }

      var doneFuture = done();
      Future<void>.delayed(const Duration(milliseconds: 2)).then((_) async {
        await (dbRecordRef.cv()..value.v = 3).put(db);
      }).unawait();
      await doneFuture;
    });

    test('onRecordSync', () async {
      var cvStore = dbIntStoreFactory.store<DbTest>('test');
      var dbRecordRef = cvStore.record(1); //
      await (dbRecordRef.cv()..value.v = 2).put(db);
      DbTest? record;
      var completer = Completer<void>();
      var subscription = dbRecordRef.onRecordSync(db).listen((event) {
        record = event;
        if (event?.value.v == 3) {
          completer.complete();
        }
      });
      var firstCompleter = Completer<void>();
      scheduleMicrotask(() {
        expect(record?.value.v, 2);
        firstCompleter.complete();
      });
      await firstCompleter.future;
      await (dbRecordRef.cv()..value.v = 3).put(db);
      await completer.future;
      expect(record?.value.v, 3);

      await subscription.cancel();
    });

    test('CvQueryRef.getRecord', () async {
      var cvStore = dbIntStoreFactory.store<DbTest>('test');
      var dbRecordRef = cvStore.record(1); //
      var dbRecordRef2 = cvStore.record(2); //
      var record = dbRecordRef.cv()..value.v = 1;
      var record2 = dbRecordRef2.cv()..value.v = 2;
      await db.transaction((txn) async {
        await record.put(txn);
        await record2.put(txn);
      });
      expect(await cvStore.query().getRecord(db), record);
      expect(await cvStore.query().getRecords(db), [record, record2]);
      expect(cvStore.query().getRecordSync(db), record);
      expect(cvStore.query().getRecordsSync(db), [record, record2]);
    });
    test('CvQueryRef.onRecordsSync', () async {
      var cvStore = dbIntStoreFactory.store<DbTest>('test');
      var dbRecordRef = cvStore.record(1); //
      var dbRecordRef2 = cvStore.record(2); //
      await dbRecordRef.put(db, dbRecordRef.cv()..value.v = 1);
      List<DbTest>? records;
      var completer = Completer<void>();
      var subscription = cvStore.query().onRecordsSync(db).listen((event) {
        records = event;
        if (records?.length == 2) {
          completer.complete();
        }
      });
      var firstCompleter = Completer<void>();
      scheduleMicrotask(() {
        expect(records, hasLength(1));
        firstCompleter.complete();
      });
      await firstCompleter.future;
      await dbRecordRef2.put(db, dbRecordRef.cv()..value.v = 2);
      await completer.future;
      expect(records, hasLength(2));
      await subscription.cancel();
    });
    test('delete', () async {
      var cvStore = dbIntStoreFactory.store<DbTest>('test');
      await db.transaction((txn) async {
        await cvStore.record(1).cv().put(txn);
        await cvStore.record(2).cv().put(txn);
        await cvStore.record(3).cv().put(txn);
        var query = cvStore.query(
          finder: Finder(sortOrders: [SortOrder(Field.key)], offset: 1),
        );
        expect(await query.delete(txn), 2);
        expect(cvStore.query().getKeysSync(txn), [1]);
      });
    });
  });
}
