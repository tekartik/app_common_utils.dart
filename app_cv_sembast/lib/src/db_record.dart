import 'package:cv/cv.dart';
import 'package:sembast/sembast.dart';
import 'package:tekartik_app_cv_sembast/src/logger_utils.dart';
import 'package:tekartik_common_utils/list_utils.dart';

import 'cv_store_ref.dart';

/// DbRecord
abstract class DbRecord<K extends RecordKeyBase> implements CvModel {
  RecordRef<K, Model>? _ref;
}

/// Access to ref.
extension DbRecordToRefExt<K extends RecordKeyBase> on DbRecord<K> {
  /// Get the record ref
  DbRecordRef<K, DbRecord<K>> get ref =>
      CvStoreRef<K, DbRecord<K>>(rawRef.store.name).record(rawRef.key);

  /// Get the record ref
  DbRecordRef<K, DbRecord<K>>? get refOrNull => hasId ? ref : null;

  /// Set the record ref
  set ref(DbRecordRef<K, DbRecord<K>> ref) => rawRef = ref.rawRef;

  /// Set the record ref
  set refOrNull(DbRecordRef<K, DbRecord<K>>? ref) =>
      ref == null ? _ref = null : this.ref = ref;

  /// Get the raw record ref
  RecordRef<K, Map<String, Object?>> get rawRef => _ref!;

  /// set the raw record ref
  ///@deprecated
  set rawRef(RecordRef<K, Map<String, Object?>> ref) => _ref = ref;

  /// Check hasId first
  K get id => rawRef.key;

  /// Id or null
  K? get idOrNull => _ref?.key;

  set idOrNull(K? id) {
    if (id == null) {
      _ref = null;
    } else {
      this.id = id;
    }
  }

  /// Only true f newly created record
  bool get hasId => _ref != null;

  /// Change the id
  set id(K id) => rawRef = rawRef.store.record(id);
}

/// Base record implementation. Protected fields:
/// - ref
abstract class DbRecordBase<K extends RecordKeyBase> extends CvModelBase
    implements DbRecord<K> {
  @override
  RecordRef<K, Model>? _ref;
  @override
  String toString() =>
      _ref == null
          ? '<null> ${super.toString()}'
          : '$rawRef ${super.toString()}';
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
class DbRecordMap<K extends RecordKeyBase> extends DbRecordBase<K> {
  late CvMapModel _mapModel;

  @override
  List<CvField> get fields => _mapModel.fields;

  /// Copy from another map
  void fromModel(Map map, {List<String>? columns}) {
    _mapModel = CvMapModel()..fromMap(map, columns: columns);
  }
}

/// Easy extension
extension DbSembastRecordSnapshotExt<K extends RecordKeyBase>
    on RecordSnapshot<K, Model> {
  /// Create a DbRecord from a snapshot
  T cv<T extends DbRecord<K>>() {
    return (cvBuildModel<T>(value)..rawRef = ref)..fromMap(value);
  }
}

/// Easy extension
extension DbSembastRecordSnapshotsExt<K extends RecordKeyBase>
    on List<RecordSnapshot<K, Model>> {
  /// Create a list of DbRecords from a snapshot
  List<T> cv<T extends DbRecord<K>>() => lazy((snapshot) => snapshot.cv<T>());
}

/// Allow list with null values.
extension DbSembastRecordSnapshotsOrNullExt<K extends RecordKeyBase>
    on List<RecordSnapshot<K, Model>?> {
  /// Create a list of DbRecords from a snapshot
  List<T?> cvOrNull<T extends DbRecord<K>>() =>
      lazy((snapshot) => snapshot?.cv<T>());
}

/// Allow Stream with null values.
extension DbSembastRecordSnapshotStreamExt<K extends RecordKeyBase>
    on Stream<List<RecordSnapshot<K, Model>?>> {
  /// Create a list of DbRecords from a snapshot
  Stream<List<T?>> cvOrNull<T extends DbRecord<K>>() =>
      map((snapshot) => snapshot.cvOrNull<T>());
}

/// Easy extension
extension DbRecordExt<K extends RecordKeyBase, V> on DbRecord<K> {}

/// Easy extension
extension DbRecordDbExt<K extends RecordKeyBase, V> on DbRecord<K> {
  /// put
  Future<void> put(DatabaseClient db, {bool merge = false}) async {
    var data = await rawRef.put(db, toMap(), merge: merge);
    fromMap(data);
  }

  /// Update inner data.
  ///
  /// return true if updated, false if not (missing)
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
  Future<bool> add(DatabaseClient db, {Model? value}) async {
    var key = await rawRef.add(db, value ?? toMap());
    return (key != null);
  }

  /// Update inner data
  Future<bool> delete(DatabaseClient db) async {
    var key = await rawRef.delete(db);
    return (key != null);
  }
}

/// Public extension on DbRecord
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
extension DbDatabaseClientSembastExt on DatabaseClient {
  /// Transaction helper
  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async {
    var dbOrTxn = this;
    if (dbOrTxn is Database) {
      return await dbOrTxn.transaction(action);
    } else {
      return action(dbOrTxn as Transaction);
    }
  }
}

/// Easy extension
extension DbRecordListExt<K extends RecordKeyBase, V> on List<DbRecord<K>> {
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
typedef CvRecordRef<K extends RecordKeyBase, V extends DbRecord<K>> =
    DbRecordRef<K, V>;

/// String record ref
typedef DbStringRecordRef<T extends DbStringRecord> = DbRecordRef<String, T>;

/// int record ref
typedef DbIntRecordRef<T extends DbIntRecord> = DbRecordRef<int, T>;

/// Record reference
class DbRecordRef<K extends RecordKeyBase, V extends DbRecord<K>> {
  /// Store
  final DbStoreRef<K, V> store;

  /// Raw ref
  final RecordRef<K, Map<String, Object?>> rawRef;

  /// Constructor
  DbRecordRef(this.store, K key) : rawRef = store.rawRef.record(key);

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'DbRecordRef(${store.name}, $key)';

  @override
  bool operator ==(Object other) {
    if (other is DbRecordRef) {
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

/// Compat
typedef CvRecordsRef<K extends RecordKeyBase, V extends DbRecord<K>> =
    DbRecordsRef<K, V>;

/// Records helpers
class DbRecordsRef<K extends RecordKeyBase, V extends DbRecord<K>> {
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
  List<DbRecordRef<K, V>> get refs =>
      keys.map((key) => store.record(key)).toList();

  /// Direct access to a record ref.
  DbRecordRef<K, V> operator [](int i) => store.record(keys[i]);

  /// Constructor
  DbRecordsRef(this.store, Iterable<K> keys)
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
    if (other is List<DbRecordRef>) {
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
extension DbRecordRefDbExt<K extends RecordKeyBase, V extends DbRecord<K>>
    on DbRecordRef<K, V> {
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

  /// Add a record.
  ///
  /// Returns the key if inserted, null otherwise.
  Future<K?> add(DatabaseClient db, V value) {
    return rawRef.add(db, value.toMap());
  }

  /// Put a record.
  Future<V> put(DatabaseClient db, V value, {bool? merge}) async =>
      (await rawRef.put(db, value.toMap(), merge: merge)).cv<V>()
        ..rawRef = rawRef;

  /// Check if exists.
  Future<bool> exists(DatabaseClient client) => rawRef.exists(client);

  /// Check if exists synchronously.
  bool existsSync(DatabaseClient client) => rawRef.existsSync(client);
}

/// Helper extension.
extension DbRecordRefExt<K extends RecordKeyBase, V extends DbRecord<K>>
    on DbRecordRef<K, V> {
  /// Key
  K get key => rawRef.key;

  /// To build for write
  V cv() => cvBuildModel<V>({})..rawRef = rawRef;

  /// Cast if needed
  DbRecordRef<RK, RV>
  cast<RK extends RecordKeyBase, RV extends DbRecord<RK>>() {
    if (this is DbRecordRef<RK, RV>) {
      return this as DbRecordRef<RK, RV>;
    }
    return store.cast<RK, RV>().record(key as RK);
  }

  /// Cast if needed
  DbRecordRef<K, RV> castV<RV extends DbRecord<K>>() => cast<K, RV>();
}

/// Helper extension.
extension DbRecordRefListExt<K extends RecordKeyBase, V extends DbRecord<K>>
    on List<DbRecordRef<K, V>> {
  /// Create new objects.
  List<V> cv() => map((ref) => ref.cv()).toList();
}

/// Helper extension.
extension DbRecordsRefExt<K extends RecordKeyBase, V extends DbRecord<K>>
    on DbRecordsRef<K, V> {
  /// Create new objects.
  List<V> cv() => refs.lazy((ref) => ref.cv());
}
