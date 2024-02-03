import 'package:sembast/blob.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/timestamp.dart';
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

class DbString2Test extends DbStringRecordBase {
  final value2 = CvField<int>('value2');

  @override
  List<CvField> get fields => [value2];
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
      cvAddConstructor(DbString2Test.new);
    });
    setUp(() async {
      db = await newDatabaseFactoryMemory().openDatabase('test');
    });
    tearDown(() {
      db.close();
    });
    test('api', () {
      // ignore: unnecessary_statements
      CvStoreRef;
      // ignore: unnecessary_statements
      CvRecordRef;
      // ignore: unnecessary_statements
      CvQueryRef;
    });
    test('ref', () async {
      var store1 = cvIntRecordFactory.store('test');
      var store2 = cvIntRecordFactory.store('test');
      expect(store1, store2);
      var record1 = store1.record(1);
      var record2 = store2.record(1);
      expect(record1, record2);
      record2 = store1.record(2);
      expect(record1, isNot(record2));
      store2 = cvIntRecordFactory.store('tes2');
      expect(store1, isNot(store2));
      record2 = store2.record(1);
      expect(record1, isNot(record2));
    });
    test('cast', () async {
      var store = cvIntRecordFactory
          .store<DbTest>('test')
          .cast<String, DbStringTest>()
          .castV<DbStringTest>();
      var record = store.record('test').cv()..value.v = 1;
      expect(record.toMap(), {'value': 1});
      var record2 = store.record('test').castV<DbString2Test>().cv()
        ..value2.v = 2;
      expect(record2.toMap(), {'value2': 2});
    });
    test('int store', () async {
      var store = intMapStoreFactory.store('test');
      var cvStore = cvIntRecordFactory.store<DbTest>('test');

      var dbTest = DbTest()..value.v = 1;
      expect(dbTest.hasId, false);
      var recordRef = store.record(1);
      var cvRecordRef = cvStore.record(1);
      expect(cvRecordRef.key, 1);
      await store.record(1).put(db, {'value': 1});
      expect(await recordRef.get(db), {'value': 1});
      expect(recordRef.getSync(db), {'value': 1});
      var readDbTest = (await cvRecordRef.get(db))!;
      expect(readDbTest, dbTest);
      expect(readDbTest.rawRef.key, 1);
      expect(readDbTest.ref.key, 1);
      var writeDbTest = cvRecordRef.cv()..value.v = 2;
      await writeDbTest.put(db);
      readDbTest = (await cvRecordRef.get(db))!;
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
      expect(writeDbTest.ref, cvRecordRef);
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
    test('document.put', () async {
      var cvStore = cvStringRecordFactory.store<DbStringTest>('test');
      var record = DbStringTest()..value.v = 1;
      var docRef = cvStore.record('test');
      await docRef.put(db, record);
      var doc = docRef.cv();
      expect(await docRef.get(db), record);
      doc.value.v = 2;
      await docRef.put(db, doc);
      expect(await docRef.get(db), doc);
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
        // print(_);
      }

      await (cvRecordRef.cv()..value.v = 1).put(db);
      try {
        await doneWithTimeOut();
        fail('should fail');
      } on TimeoutException catch (_) {
        // print(_);
      }

      await (cvRecordRef.cv()..value.v = 3).put(db);
      await done();

      await (cvRecordRef.cv()..value.v = 1).put(db);
      try {
        await doneWithTimeOut();
        fail('should fail');
      } on TimeoutException catch (_) {
        // print(_);
      }

      var doneFuture = done();
      Future<void>.delayed(Duration(milliseconds: 2)).then((_) async {
        await (cvRecordRef.cv()..value.v = 3).put(db);
      }).unawait();
      await doneFuture;
    });

    test('onRecordSync', () async {
      var cvStore = cvIntRecordFactory.store<DbTest>('test');
      var cvRecordRef = cvStore.record(1); //
      await (cvRecordRef.cv()..value.v = 2).put(db);
      DbTest? record;
      var completer = Completer<void>();
      var subscription = cvRecordRef.onRecordSync(db).listen((event) {
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
      await (cvRecordRef.cv()..value.v = 3).put(db);
      await completer.future;
      expect(record?.value.v, 3);

      await subscription.cancel();
    });

    test('fillModel', () async {
      var allFields = CvDbAllFields()..fillModel(cvSembastFillOptions1);
      expect(allFields.toMap(), {
        'int': 1,
        'double': 2.5,
        'bool': 3.5,
        'string': 4.5,
        'timestamp': Timestamp.parse('1970-01-01T00:00:05.000Z'),
        'intList': [6],
        'model': {'value': 7},
        'modelList': {'value': 8},
        'map': {'value': 9},
        'blob': Blob.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
      });
    });

    group('CvQueryRef', () {
      test('CvQueryRef.onRecordsSync', () async {
        var cvStore = cvIntRecordFactory.store<DbTest>('test');
        var cvRecordRef = cvStore.record(1); //
        var cvRecordRef2 = cvStore.record(2); //
        await cvRecordRef.put(db, cvRecordRef.cv()..value.v = 1);
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
        await cvRecordRef2.put(db, cvRecordRef.cv()..value.v = 2);
        await completer.future;
        expect(records, hasLength(2));
        await subscription.cancel();
      });
    });
  });
}

class CvDbAllFields extends DbIntRecordBase {
  final intValue = CvField<int>('int');
  final doubleValue = CvField<double>('double');
  final boolValue = CvField<double>('bool');
  final stringValue = CvField<double>('string');
  final timestampValue = CvField<Timestamp>('timestamp');
  final intListValue = CvListField<int>('intList');
  final model = CvModelField<DbStringTest>('model');
  final modelList = CvModelField<DbStringTest>('modelList');
  final map = CvField<Model>('map');
  final blob = CvField<Blob>('blob');

  @override
  List<CvField> get fields => [
        intValue,
        doubleValue,
        boolValue,
        stringValue,
        timestampValue,
        intListValue,
        model,
        modelList,
        map,
        blob
      ];
}
