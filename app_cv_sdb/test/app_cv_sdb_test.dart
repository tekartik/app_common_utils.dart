import 'dart:typed_data';

import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:test/test.dart';

class DbTest extends ScvIntRecordBase {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

class DbUserProject extends ScvIntRecordBase {
  final userId = CvField<int>('user_id');
  final projectId = CvField<String>('project_id');

  @override
  List<CvField> get fields => [userId, projectId];
}

final dbUserProjectModel = DbUserProject();

final dbIntTestStore = scvIntStoreFactory.store<DbTest>('int_test');
var dbIntTestIndex = dbIntTestStore.index('value_index');

class DbStringTest extends ScvStringRecordBase {
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

final dbStringTestStore = scvStringStoreFactory.store<DbStringTest>(
  'string_test',
);

class DbString2Test extends ScvStringRecordBase {
  final value2 = CvField<int>('value2');

  @override
  List<CvField> get fields => [value2];
}

class DbTimestampTest extends ScvStringRecordBase {
  final timestamp = cvEncodedTimestampField('timestamp');

  @override
  List<CvField> get fields => [timestamp];
}

class DbBlobTest extends ScvStringRecordBase {
  final blob = cvEncodedBlobField('blob');

  @override
  List<CvField> get fields => [blob];
}

class DbTimestamp2Test extends ScvIntRecordBase {
  final timestamp = cvEncodedTimestampField('timestamp');

  @override
  List<CvField> get fields => [timestamp];
}

final scvTimestampStore = scvStoreRef<String, DbTimestampTest>(
  'timestamp_store',
);
final scvBlobStore = scvStoreRef<String, DbBlobTest>('blob_store');
final scvTimestamp2Store = scvStoreRef<int, DbTimestamp2Test>(
  'timestamp_store',
);
final userProjectStore = scvIntStoreFactory.store<DbUserProject>(
  'user_project',
);
final userProjectIndex = userProjectStore.index2<int, String>(
  'user_project_id',
);
final userProjectIndexSchema = userProjectIndex.schema(
  keyPath: [dbUserProjectModel.userId.key, dbUserProjectModel.projectId.key],
);

bool contentAndKeyEquals(ScvRecord? record1, ScvRecord? record2) {
  return record1?.rawRef == record2?.rawRef && record1 == record2;
}

void checkContentAndKeyEquals(ScvRecord? record1, ScvRecord? record2) {
  expect(
    contentAndKeyEquals(record1, record2),
    isTrue,
    reason: 'record1: $record1, record2: $record2',
  );
}

void main() {
  setUpAll(() {
    cvAddConstructors([
      DbTest.new,
      DbStringTest.new,
      DbString2Test.new,
      DbTimestampTest.new,
      DbBlobTest.new,
    ]);
  });
  group('ref', () {
    test('toMap', () async {
      var store = scvIntStoreFactory.store<DbTest>('test');
      var record1 = store.record(1).cv();
      var record2 = store.record(2).cv();
      expect([record1, record2].toMap(), {1: record1, 2: record2});
    });
    test('toString', () {
      var record = DbUserProject()..userId.v = 1;
      expect(record.toString(), '<null> {user_id: 1}');
      var store = scvIntStoreFactory.store<DbTest>('test');
      var record1 = store.record(1).cv();
      expect(record1.toString(), 'Record(test, 1) {}');
    });
    test('timestamp', () async {
      var store = scvTimestampStore;
      var record1 = store.record('1').cv();
      expect(record1.toMap(), isEmpty);
      var now = ScvTimestamp.now();
      record1.timestamp.value = now;
      expect(record1.toMap(), {'timestamp': now.toDateTime(isUtc: true)});
      var record1Bis = store.record('1bis').cv()..fromMap(record1.toMap());
      expect(record1Bis, record1);
      var record2 = store.record('2').cv();
      expect([record1, record2].toMap(), {'1': record1, '2': record2});
    });
    test('blob', () async {
      var store = scvBlobStore;
      var record1 = store.record('1').cv();
      expect(record1.toMap(), isEmpty);
      var bytes = Uint8List.fromList([1, 2, 3]);
      record1.blob.value = ScvBlob(bytes);
      expect(record1.toMap(), {'blob': bytes});
      var record1Bis = store.record('1bis').cv()..fromMap(record1.toMap());
      expect(record1Bis, record1);
      var record2 = store.record('2').cv();
      expect([record1, record2].toMap(), {'1': record1, '2': record2});
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
      var original = scvIntStoreFactory.store<DbTest>('test').record(1).cv()
        ..value.v = 2;
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
      var store = scvIntStoreFactory
          .store<DbTest>('test')
          .cast<String, DbStringTest>()
          .castV<DbStringTest>();
      var record = store.record('test').cv()..value.v = 1;
      expect(record.toMap(), {'value': 1});
      var record2 = store.record('test').castV<DbString2Test>().cv()
        ..value2.v = 2;
      expect(record2.toMap(), {'value2': 2});
    });
    test('index', () async {
      var store = dbIntTestStore;
      var index = store.index<int>('value');
      expect(index.store, store);
      expect(index.name, 'value');
    });
  });
}
