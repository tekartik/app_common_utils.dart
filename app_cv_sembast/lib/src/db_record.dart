import 'package:cv/cv.dart';
import 'package:sembast/sembast.dart';
import 'package:tekartik_app_cv_sembast/src/logger_utils.dart';

import 'cv_store_ref.dart';

mixin _WithRef<K> {
  RecordRef<K, Map<String, Object?>> get rawRef => _ref!;

  //@deprecated
  set rawRef(RecordRef<K, Map<String, Object?>> ref) => _ref = ref;
  RecordRef<K, Map<String, Object?>>? _ref;

  /// Check hasId first
  K get id => rawRef.key;

  K? get idOrNull => _ref?.key;

  /// Only true f newly created record
  bool get hasId => _ref != null;

  /// Change the id
  set id(K id) => rawRef = rawRef.store.record(id);
}

/// DbRecord
abstract class DbRecord<K> extends CvModelBase with _WithRef<K> {
  /// Put(add/update) inner data
  Future<void> put(DatabaseClient db, {bool merge});

  /// Update inner data.
  Future<bool> update(DatabaseClient db);

  /// Add data.
  Future<bool> add(DatabaseClient db);

  /// Delete data.
  Future<bool> delete(DatabaseClient db);
}

/// Access to ref.
extension DbRecordToRefExt<K> on DbRecord<K> {
  /// Get the record ref
  CvRecordRef<K, DbRecord<K>> get ref =>
      CvStoreRef<K, DbRecord<K>>(rawRef.store.name).record(rawRef.key);

  /// Set the record ref
  set ref(CvRecordRef<K, DbRecord<K>> ref) => rawRef = ref.rawRef;
}

/// Base record implementation. Protected fields:
/// - ref
abstract class DbRecordBase<K> extends CvModelBase
    with _WithRef<K>
    implements DbRecord<K> {
  @override
  String toString() => _ref == null
      ? '<null> ${super.toString()}'
      : '$rawRef ${super.toString()}';

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
typedef DbStringRecord = DbRecord<String>;

/// Record with an int key
typedef DbIntRecord = DbRecord<int>;

/// Generic map
class DbRecordMap<K> extends DbRecordBase<K> {
  late CvMapModel _mapModel;

  @override
  List<CvField> get fields => _mapModel.fields;

  /// Copy from another map
  void fromModel(Map map, {List<String>? columns}) {
    _mapModel = CvMapModel()..fromMap(map, columns: columns);
  }
}

/// Easy extension
extension CvSembastRecordSnapshotExt<K> on RecordSnapshot<K, Model> {
  /// Create a DbRecord from a snapshot
  T cv<T extends DbRecord<K>>() {
    return (cvBuildModel<T>(value)..rawRef = ref)..fromMap(value);
  }
}

/// Easy extension
extension CvSembastRecordSnapshotsExt<K> on List<RecordSnapshot<K, Model>> {
  /// Create a list of DbRecords from a snapshot
  List<T> cv<T extends DbRecord<K>>() =>
      map((snapshot) => snapshot.cv<T>()).toList();
}

/// Allow list with null values.
extension CvSembastRecordSnapshotsOrNullExt<K>
    on List<RecordSnapshot<K, Model>?> {
  /// Create a list of DbRecords from a snapshot
  List<T?> cvOrNull<T extends DbRecord<K>>() =>
      map((snapshot) => snapshot?.cv<T>()).toList();
}

/// Allow Stream with null values.
extension CvSembastRecordSnapshotStreamExt<K>
    on Stream<List<RecordSnapshot<K, Model>?>> {
  /// Create a list of DbRecords from a snapshot
  Stream<List<T?>> cvOrNull<T extends DbRecord<K>>() =>
      map((snapshot) => snapshot.cvOrNull<T>());
}

/// Easy extension
extension DbRecordExt<K, V> on DbRecord<K> {
  /// put
  Future<void> put(DatabaseClient db, {bool merge = false}) async {
    var data = await rawRef.put(db, toMap(), merge: merge);
    fromMap(data);
  }

  /// delete
  Future<void> delete(DatabaseClient db) async {
    await rawRef.delete(db);
  }
}

/// Public extension on CvModelWrite
extension DbRecordCloneExt<T extends DbRecord> on T {
  /// Copy content and ref if not null
  T dbClone() {
    var newRecord = clone();
    if (hasId) {
      newRecord.rawRef = rawRef;
    }
    return newRecord;
  }
}

/// transaction helper
extension DatabaseClientSembastExt on DatabaseClient {
  /// Transaction helper
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
extension DbRecordListExt<K, V> on List<DbRecord<K>> {
  /// List of ifs
  List<K> get ids => map((record) => record.id).toList();

  /// put
  Future<void> put(DatabaseClient db, {bool merge = false}) async {
    await db.transaction((txn) async {
      for (var record in this) {
        await record.put(txn, merge: merge);
      }
    });
  }

  /// delete
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

/// Compat
typedef CvRecordRef<K, V extends DbRecord<K>> = DbRecordRef<K, V>;

/// String record ref
typedef DbStringRecordRef<T extends DbStringRecord> = DbRecordRef<String, T>;

/// int record ref
typedef DbIntRecordRef<T extends DbIntRecord> = DbRecordRef<int, T>;

/// Record reference
class DbRecordRef<K, V extends DbRecord<K>> {
  /// Store
  final CvStoreRef<K, V> store;

  /// Raw ref
  final RecordRef<K, Map<String, Object?>> rawRef;

  /// Key
  K get key => rawRef.key;

  /// Constructor
  DbRecordRef(this.store, K key) : rawRef = store.rawRef.record(key);

  /// To build for write
  V cv() => cvBuildModel<V>({})..rawRef = rawRef;

  /// Get
  Future<V?> get(DatabaseClient db) async =>
      (await rawRef.getSnapshot(db))?.cv<V>();

  /// Get synchronously
  V? getSync(DatabaseClient db) => rawRef.getSnapshotSync(db)?.cv<V>();

  /// Track changes
  Stream<V?> onRecord(Database db) =>
      rawRef.onSnapshot(db).map((event) => event?.cv<V>());

  /// Track changes, first event is emitted synchronously.
  Stream<V?> onRecordSync(Database db) =>
      rawRef.onSnapshotSync(db).map((event) => event?.cv<V>());

  /// Delete
  Future<void> delete(DatabaseClient client) async {
    await rawRef.delete(client);
  }

  /// Get
  Future<V> put(DatabaseClient db, V value, {bool? merge}) async =>
      (await rawRef.put(db, value.toMap(), merge: merge)).cv<V>()
        ..rawRef = rawRef;

  /// Check if exists.
  Future<bool> exists(DatabaseClient client) => rawRef.exists(client);

  /// Check if exists synchronously.
  bool existsSync(DatabaseClient client) => rawRef.existsSync(client);

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'CvRecordRef(${store.name}, $key)';

  @override
  bool operator ==(Object other) {
    if (other is CvRecordRef) {
      if (other.store != store) {
        return false;
      }
      if (other.key != key) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Records helpers
class CvRecordsRef<K, V extends DbRecord<K>> {
  /// Store
  final CvStoreRef<K, V> store;

  /// Raw ref
  final RecordsRef<K, Model> rawRefs;

  /// Raw ref
  @Deprecated('Use rawRefs')
  RecordsRef<K, Model> get rawRef => rawRefs;

  /// Keys
  List<K> get keys => rawRefs.keys;

  /// Record refs
  List<CvRecordRef<K, V>> get refs =>
      keys.map((key) => store.record(key)).toList();

  /// Direct access to a record ref.
  CvRecordRef<K, V> operator [](int i) => store.record(keys[i]);

  /// Constructor
  CvRecordsRef(this.store, Iterable<K> keys)
      : rawRefs = store.rawRef.records(keys);

  /// Get
  Future<List<V?>> get(DatabaseClient db) async =>
      (await rawRefs.getSnapshots(db)).cvOrNull<V>();

  /// Get synchronously
  List<V?> getSync(DatabaseClient db) =>
      rawRefs.getSnapshotsSync(db).cvOrNull<V>();

  /// Track changes
  Stream<List<V?>> onRecords(Database db) =>
      rawRefs.onSnapshots(db).map((event) => event.cvOrNull<V>());

  /// Delete
  Future<void> delete(DatabaseClient client) async {
    await rawRefs.delete(client);
  }

  @override
  int get hashCode => keys.length;

  @override
  String toString() => 'CvRecordsRef(${store.name}, ${logTruncateAny(keys)})';

  @override
  bool operator ==(Object other) {
    if (other is List<CvRecordRef>) {
      for (var i = 0; i < keys.length; i++) {
        if (other[i].store != store) {
          return false;
        }
        if (other[i].key != keys[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

/// Helper extension.
extension CvRecordRefExt<K, V extends DbRecord<K>> on CvRecordRef<K, V> {
  /// Cast if needed
  CvRecordRef<RK, RV> cast<RK, RV extends DbRecord<RK>>() {
    if (this is CvRecordRef<RK, RV>) {
      return this as CvRecordRef<RK, RV>;
    }
    return store.cast<RK, RV>().record(key as RK);
  }

  /// Cast if needed
  CvRecordRef<K, RV> castV<RV extends DbRecord<K>>() => cast<K, RV>();
}

/// Helper extension.
extension CvRecordRefListExt<K, V extends DbRecord<K>>
    on List<CvRecordRef<K, V>> {
  /// Create new objects.
  List<V> cv() => map((ref) => ref.cv()).toList();
}

/// Helper extension.
extension CvRecordsRefExt<K, V extends DbRecord<K>> on CvRecordsRef<K, V> {
  /// Create new objects.
  List<V> cv() => refs.map((ref) => ref.cv()).toList();
}
