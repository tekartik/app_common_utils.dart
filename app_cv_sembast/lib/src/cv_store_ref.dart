import 'package:sembast/sembast.dart';

import 'cv_query_ref.dart';
import 'db_record.dart';

var _mainStore = intMapStoreFactory.store().name;

/// compat
typedef CvStoreRef<K extends RecordKeyBase, V extends DbRecord<K>> =
    DbStoreRef<K, V>;

/// Int store key
typedef DbIntStoreRef<V extends DbIntRecord> = DbStoreRef<int, V>;

/// String store key
typedef DbStringStoreRef<V extends DbStringRecord> = DbStoreRef<String, V>;

/// Store helper
class DbStoreRef<K extends RecordKeyBase, V extends DbRecord<K>> {
  /// Raw ref
  final StoreRef<K, Map<String, Object?>> rawRef;

  /// Constructor
  DbStoreRef(String name) : rawRef = StoreRef<K, Map<String, Object?>>(name);

  /// A pointer to the main store
  factory DbStoreRef.main() => CvStoreRef<K, V>(_mainStore);

  @override
  String toString() => 'CvStoreRef($name)';

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is CvStoreRef) {
      if (other.name != name) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Common helpers
extension CvStoreRefExt<K extends RecordKeyBase, V extends DbRecord<K>>
    on CvStoreRef<K, V> {
  /// Name
  String get name => rawRef.name;

  /// Record ref
  DbRecordRef<K, V> record(K key) => DbRecordRef<K, V>(this, key);

  /// Records
  DbRecordsRef<K, V> records(Iterable<K> keys) =>
      DbRecordsRef<K, V>(this, keys);

  /// Query
  DbQueryRef<K, V> query({Finder? finder}) =>
      DbQueryRef<K, V>(rawRef.query(finder: finder));

  /// Find
  Future<List<V>> find(DatabaseClient db, {Finder? finder}) =>
      query(finder: finder).getRecords(db);

  /// Find first
  Future<V?> findFirst(DatabaseClient db, {Finder? finder}) =>
      query(finder: finder).getRecord(db);

  /// Add
  Future<V> add(DatabaseClient db, V record) async {
    var key = await rawRef.add(db, record.toMap());
    record.rawRef = rawRef.record(key);
    return record;
  }

  /// Delete
  Future<int> delete(DatabaseClient db, {Finder? finder}) async {
    var count = await rawRef.delete(db, finder: finder);
    return count;
  }

  /// Cast if needed
  DbStoreRef<RK, RV> cast<RK extends RecordKeyBase, RV extends DbRecord<RK>>() {
    if (this is CvStoreRef<RK, RV>) {
      return this as CvStoreRef<RK, RV>;
    }
    return CvStoreRef<RK, RV>(name);
  }

  /// Cast if needed
  DbStoreRef<K, RV> castV<RV extends DbRecord<K>>() => cast<K, RV>();
}
