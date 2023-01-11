import 'package:cv/cv.dart';
import 'package:sembast/sembast.dart';

import 'db_store.dart';

mixin _WithRef<K extends Object> {
  RecordRef<K, Map<String, Object?>> get rawRef => _ref!;

  //@deprecated
  set rawRef(RecordRef<K, Map<String, Object?>> ref) => _ref = ref;
  RecordRef<K, Map<String, Object?>>? _ref;

  /// Check hasId first
  K get id => rawRef.key;

  K? get idOrNull => _ref?.key;

  /// Only true f newly created record
  bool get hasId => _ref != null;

  set id(K id) => rawRef = rawRef.store.record(id);
}

abstract class DbRecord<K extends Object> extends CvModelBase with _WithRef<K> {
  Future<void> put(DatabaseClient db, {bool merge});

  Future<bool> update(DatabaseClient db);

  Future<bool> add(DatabaseClient db);

  Future<bool> delete(DatabaseClient db);
}

extension DbRecord2Ext<K extends Object> on DbRecord<K> {
  CvRecordRef<K, DbRecord<K>> get ref =>
      CvStoreRef<K, DbRecord<K>>(rawRef.store.name).record(rawRef.key);
}

abstract class DbRecordBase<K extends Object> extends CvModelBase
    with _WithRef<K>
    implements DbRecord<K> {
  @override
  String toString() =>
      _ref == null ? '<null_ref_record>' : '$rawRef ${super.toString()}';

  /// Put(add/update) inner data
  ///
  /// [value] is by default toMap()
  @override
  Future<void> put(DatabaseClient db, {Model? value, bool? merge}) async {
    var model = await rawRef.put(db, value ?? toMap(), merge: merge);
    fromMap(model);
  }

  /// Update inner data.
  ///
  /// return true if updated, false if not (missing)
  @override
  Future<bool> update(DatabaseClient db, {Model? value}) async {
    var model = await rawRef.update(db, value ?? toMap());
    if (model != null) {
      fromMap(model);
      return true;
    } else {
      return false;
    }
  }

  /// Add data.
  ///
  /// return true if added, false if not (existing)
  @override
  Future<bool> add(DatabaseClient db, {Model? value}) async {
    var key = await rawRef.add(db, value ?? toMap());
    return (key != null);
  }

  /// Update inner data
  @override
  Future<bool> delete(DatabaseClient db) async {
    var key = await rawRef.delete(db);
    return (key != null);
  }
}

/// Record with a string key
abstract class DbStringRecordBase extends DbRecordBase<String>
    implements DbStringRecord {}

/// Record with an int key
abstract class DbIntRecordBase extends DbRecordBase<int>
    implements DbIntRecord {}

/// Record with a string key
abstract class DbStringRecord extends DbRecord<String> {}

/// Record with an int key
abstract class DbIntRecord extends DbRecord<int> {}

/// Generic map
class DbRecordMap<K extends Object> extends DbRecordBase<K> {
  late CvMapModel _mapModel;

  @override
  List<CvField> get fields => _mapModel.fields;

  void fromModel(Map map, {List<String>? columns}) {
    _mapModel = CvMapModel()..fromMap(map, columns: columns);
  }
}

/// Easy extension
extension CvSembastRecordSnapshotExt<K extends Object>
    on RecordSnapshot<K, Map<String, Object?>> {
  /// Create a DbRecord from a snapshot
  T cv<T extends DbRecord<K>>() {
    return (cvBuildModel<T>(value)..rawRef = ref)..fromMap(value);
  }
}

/// Easy extension
extension CvSembastRecordSnapshotsExt<K extends Object>
    on List<RecordSnapshot<K, Map<String, Object?>>> {
  /// Create a list of DbRecords from a snapshot
  List<T> cv<T extends DbRecord<K>>() =>
      map((snapshot) => snapshot.cv<T>()).toList();
}

/// Easy extension
extension DbRecordExt<K extends Object, V> on DbRecord<K> {
  Future<void> put(DatabaseClient db, {bool merge = false}) async {
    var data = await rawRef.put(db, toMap(), merge: merge);
    fromMap(data);
  }

  Future<void> delete(DatabaseClient db) async {
    await rawRef.delete(db);
  }

/*
  /// Weird, this reads onto an existing record...
  Future<bool> get(DatabaseClient db) async {

  }*/
}

extension DatabaseClientSembastExt on DatabaseClient {
  Future<T> transaction<T>(
      Future<T> Function(Transaction transaction) action) async {
    var dbOrTxn = this;
    if (dbOrTxn is Database) {
      return await dbOrTxn.transaction(action);
    } else {
      return action(dbOrTxn as Transaction);
    }
  }
}

/// Easy extension
extension DbRecordListExt<K extends Object, V extends Object>
    on List<DbRecord<K>> {
  Future<void> put(DatabaseClient db, {bool merge = false}) async {
    await db.transaction((txn) async {
      for (var record in this) {
        await record.put(txn, merge: merge);
      }
    });
  }

  Future<int> delete(DatabaseClient db) {
    return db.transaction((txn) async {
      var count = 0;
      for (var record in this) {
        if (await record.delete(txn)) {
          count++;
        }
      }
      return count;
    });
  }

/*
  /// Weird, this reads onto an existing record...
  Future<bool> get(DatabaseClient db) async {

  }*/
}

class CvRecordRef<K extends Object, V extends DbRecord<K>> {
  final CvStoreRef<K, V> store;
  final RecordRef<K, Map<String, Object?>> rawRef;

  CvRecordRef(this.store, K key) : rawRef = store.rawRef.record(key);

  /// To build for write
  V cv() => cvBuildModel<V>({})..rawRef = rawRef;

  /// Get
  Future<V?> get(DatabaseClient db) async =>
      (await rawRef.getSnapshot(db))?.cv<V>();

  /// Track changes
  Stream<V?> onRecord(Database db) =>
      rawRef.onSnapshot(db).map((event) => event?.cv<V>());

  Future<void> delete(DatabaseClient client) async {
    await rawRef.delete(client);
  }
}
