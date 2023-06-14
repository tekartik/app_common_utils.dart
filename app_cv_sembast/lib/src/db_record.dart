import 'package:cv/cv.dart';
import 'package:sembast/sembast.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:tekartik_app_cv_sembast/src/logger_utils.dart';

import 'db_store.dart';

Stream<List<V>> combineLatestStreams<V>(Iterable<Stream<V>> streams) {
  final first = streams.first;
  final others = <Stream<V>>[...streams.skip(1)];
  return first.combineLatestAll(others);
}

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

  set id(K id) => rawRef = rawRef.store.record(id);
}

abstract class DbRecord<K> extends CvModelBase with _WithRef<K> {
  Future<void> put(DatabaseClient db, {bool merge});

  Future<bool> update(DatabaseClient db);

  Future<bool> add(DatabaseClient db);

  Future<bool> delete(DatabaseClient db);
}

/// Access to ref.
extension DbRecordToRefExt<K> on DbRecord<K> {
  CvRecordRef<K, DbRecord<K>> get ref =>
      CvStoreRef<K, DbRecord<K>>(rawRef.store.name).record(rawRef.key);
}

abstract class DbRecordBase<K> extends CvModelBase
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
class DbRecordMap<K> extends DbRecordBase<K> {
  late CvMapModel _mapModel;

  @override
  List<CvField> get fields => _mapModel.fields;

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

/// Easy extension
extension DbRecordExt<K, V> on DbRecord<K> {
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
extension DbRecordListExt<K, V> on List<DbRecord<K>> {
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

class CvRecordRef<K, V extends DbRecord<K>> {
  final CvStoreRef<K, V> store;
  final RecordRef<K, Map<String, Object?>> rawRef;

  K get key => rawRef.key;

  CvRecordRef(this.store, K key) : rawRef = store.rawRef.record(key);

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

  Future<void> delete(DatabaseClient client) async {
    await rawRef.delete(client);
  }

  /// Check if exists.
  Future<void> exists(DatabaseClient client) async {
    await rawRef.exists(client);
  }

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
  final CvStoreRef<K, V> store;
  final RecordsRef<K, Model> rawRef;

  List<K> get keys => rawRef.keys;

  List<CvRecordRef<K, V>> get refs =>
      keys.map((key) => store.record(key)).toList();

  /// Direct access to a record ref.
  CvRecordRef<K, V> operator [](int i) => store.record(keys[i]);

  CvRecordsRef(this.store, Iterable<K> keys)
      : rawRef = store.rawRef.records(keys);

  /// Get
  Future<List<V?>> get(DatabaseClient db) async =>
      (await rawRef.getSnapshots(db)).cvOrNull<V>();

  /// Get synchronously
  List<V?> getSync(DatabaseClient db) =>
      rawRef.getSnapshotsSync(db).cvOrNull<V>();

  /// Track changes
  Stream<List<V?>> onRecords(Database db) =>
      combineLatestStreams(refs.map((ref) => ref.onRecord(db)));

  Future<void> delete(DatabaseClient client) async {
    await rawRef.delete(client);
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
