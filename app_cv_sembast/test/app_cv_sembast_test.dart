import 'package:sembast/blob.dart';
import 'package:sembast/timestamp.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';
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
  final value = CvField<int>('value');
  final value2 = CvField<int>('value2');

  @override
  List<CvField> get fields => [value, value2];
}

bool contentAndKeyEquals(DbRecord? record1, DbRecord? record2) {
  return record1?.rawRef == record2?.rawRef && record1 == record2;
}

void main() {
  group('store', () {
    setUpAll(() {
      cvAddConstructors([DbTest.new, DbStringTest.new, DbString2Test.new]);
    });

    test('api', () {
      // ignore: unnecessary_statements
      CvStoreRef;
      // ignore: unnecessary_statements
      DbRecordRef;
      // ignore: unnecessary_statements
      CvQueryRef;
      // Compat
      // ignore: unnecessary_statements
      CvRecordRef;
      // ignore: unnecessary_statements
      CvRecordsRef;
    });
    test('toMap', () async {
      var store = dbIntStoreFactory.store<DbTest>('test');
      var record1 = store.record(1).cv();
      var record2 = store.record(2).cv();
      expect([record1, record2].toMap(), {1: record1, 2: record2});
    });
    test('ref', () async {
      var store1 = dbIntStoreFactory.store('test');
      var store2 = dbIntStoreFactory.store('test');
      expect(store1, store2);
      var record1 = store1.record(1);
      var record2 = store2.record(1);
      expect(record1, record2);
      record2 = store1.record(2);
      expect(record1, isNot(record2));
      store2 = dbIntStoreFactory.store('tes2');
      expect(store1, isNot(store2));
      record2 = store2.record(1);
      expect(record1, isNot(record2));
    });
    test('int.ref', () async {
      var store = dbIntStoreFactory.store<DbTest>('store');
      var record = store.record(1);
      expect(record, isA<DbIntRecordRef<DbTest>>());
      var dbRecordRef = DbIntRecordRef(store, 1);
      expect(dbRecordRef, isA<DbIntRecordRef<DbTest>>());
      dbRecordRef = store.record(2);
      expect(dbRecordRef, isA<DbIntRecordRef<DbTest>>());
    });
    test('string.ref', () async {
      var store = dbStringStoreFactory.store<DbStringTest>('store');
      var record = store.record('test');
      expect(record, isA<DbStringRecordRef<DbStringTest>>());
      var dbRecordRef = DbStringRecordRef(store, 'test');
      expect(dbRecordRef, isA<DbStringRecordRef<DbStringTest>>());
      dbRecordRef = store.record('test2');
      expect(dbRecordRef, isA<DbStringRecordRef<DbStringTest>>());
    });
    test('model.ref', () {
      var store = dbIntStoreFactory.store<DbTest>('test');
      var record = store.record(1);
      var dbRecord = record.cv();
      expect(dbRecord.ref, record);
      expect(dbRecord.refOrNull, record);
      dbRecord.ref = store.record(2);
      expect(dbRecord.id, 2);
      expect(dbRecord.idOrNull, 2);
      dbRecord = DbTest();
      expect(dbRecord.hasId, isFalse);
      dbRecord.ref = store.record(2);
      expect(dbRecord.id, 2);
      expect(dbRecord.hasId, isTrue);
      dbRecord.idOrNull = 3;
      expect(dbRecord.id, 3);
      dbRecord.refOrNull = null;
      expect(dbRecord.idOrNull, isNull);
      dbRecord.refOrNull = record;
      expect(dbRecord.id, 1);

      var list = [dbRecord, store.record(3).cv()];
      expect(list.ids, [1, 3]);
    });
    test('clone', () async {
      var original = dbIntStoreFactory.store<DbTest>('test').record(1).cv()
        ..value.v = 2;
      var record = original.dbClone();
      expect(record, original);
      expect(record, isNot(same(original)));
      expect(record.value.v, 2);
      expect(record.id, 1);

      original = DbTest()..value.v = 3;
      record = original.dbClone();
      expect(record, original);
      expect(record, isNot(same(original)));
      expect(record.value.v, 3);
      expect(record.idOrNull, isNull);
    });
    test('cast', () async {
      var store = dbIntStoreFactory
          .store<DbTest>('test')
          .cast<String, DbStringTest>()
          .castV<DbStringTest>();
      var record = store.record('test').cv()..value.v = 1;
      expect(record.toMap(), {'value': 1});
      var record2 = store.record('test').castV<DbString2Test>().cv()
        ..value2.v = 2;
      expect(record2.toMap(), {'value2': 2});
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
        'blob': Blob.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
      });
    });
    test('toJsonEncodable', () async {
      var allFields = CvDbAllFields()..fillModel(cvSembastFillOptions1);
      expect(allFields.toJsonEncodable(), {
        'int': 1,
        'double': 2.5,
        'bool': 3.5,
        'string': 4.5,
        'timestamp': {'@Timestamp': '1970-01-01T00:00:05.000Z'},
        'intList': [6],
        'model': {'value': 7},
        'modelList': {'value': 8},
        'map': {'value': 9},
        'blob': {'@Blob': 'AAECAwQFBgcICQ=='},
      });
      var tests = [DbTest()..value.v = 1, DbTest()..value.v = 2];
      expect(tests.toJsonEncodable(), [
        {'value': 1},
        {'value': 2},
      ]);
    });
    test('json', () async {
      var record = CvDbAllFields()..timestampValue.v = Timestamp(1, 2000);
      expect(
        record.dbToJson(),
        '{"timestamp":{"@Timestamp":"1970-01-01T00:00:01.000002Z"}}',
      );
      expect(
        record.dbToJsonPretty(),
        '{\n'
        '  "timestamp": {\n'
        '    "@Timestamp": "1970-01-01T00:00:01.000002Z"\n'
        '  }\n'
        '}',
      );
      expect(
        [record].dbToJson(),
        '[{"timestamp":{"@Timestamp":"1970-01-01T00:00:01.000002Z"}}]',
      );
      expect(
        [record].dbToJsonPretty(),
        '[\n'
        '  {\n'
        '    "timestamp": {\n'
        '      "@Timestamp": "1970-01-01T00:00:01.000002Z"\n'
        '    }\n'
        '  }\n'
        ']',
      );
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
    blob,
  ];
}
