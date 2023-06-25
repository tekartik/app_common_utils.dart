import 'package:sembast/sembast.dart';

import 'db_record.dart';

/// Store factory mixin.
mixin CvStoreFactoryMixin<K> implements CvStoreFactory<K> {
  @override
  CvStoreRef<K, V> store<V extends DbRecord<K>>([String? name]) {
    if (name == null) {
      return CvStoreRef<K, V>.main();
    } else {
      return CvStoreRef<K, V>(name);
    }
  }
}

var _mainStore = intMapStoreFactory.store().name;

/// Store helper
class CvStoreRef<K, V extends DbRecord<K>> {
  final StoreRef<K, Map<String, Object?>> rawRef;

  CvStoreRef(String name) : rawRef = StoreRef<K, Map<String, Object?>>(name);

  /// A pointer to the main store
  factory CvStoreRef.main() => CvStoreRef<K, V>(_mainStore);

  String get name => rawRef.name;

  CvRecordRef<K, V> record(K key) => CvRecordRef<K, V>(this, key);

  /// Records
  CvRecordsRef<K, V> records(Iterable<K> keys) =>
      CvRecordsRef<K, V>(this, keys);

  /// Query
  CvQueryRef<K, V> query({Finder? finder}) =>
      CvQueryRef<K, V>(rawRef.query(finder: finder));

  Future<List<V>> find(DatabaseClient db, {Finder? finder}) =>
      query(finder: finder).getRecords(db);

  Future<V?> findFirst(DatabaseClient db, {Finder? finder}) =>
      query(finder: finder).getRecord(db);

  Future<V> add(DatabaseClient db, V record) async {
    var key = await rawRef.add(db, record.toMap());
    record.rawRef = rawRef.record(key);
    return record;
  }

  Future<int> delete(DatabaseClient db, {Finder? finder}) async {
    var count = await rawRef.delete(db, finder: finder);
    return count;
  }

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

/// Helper extension.
extension CvStoreRefExt<K, V extends DbRecord<K>> on CvStoreRef<K, V> {
  /// Cast if needed
  CvStoreRef<RK, RV> cast<RK, RV extends DbRecord<RK>>() {
    if (this is CvStoreRef<RK, RV>) {
      return this as CvStoreRef<RK, RV>;
    }
    return CvStoreRef<RK, RV>(name);
  }

  /// Cast if needed
  CvStoreRef<K, RV> castV<RV extends DbRecord<K>>() => cast<K, RV>();
}

class CvQueryRef<K, V extends DbRecord<K>> {
  final QueryRef<K, Map<String, Object?>> rawRef;

  CvQueryRef(this.rawRef);

  Future<V?> getRecord(DatabaseClient db) async {
    return (await rawRef.getSnapshot(db))?.cv();
  }

  Future<List<V>> getRecords(DatabaseClient db) async {
    return (await rawRef.getSnapshots(db)).cv();
  }

  /// Track changes
  Stream<V?> onRecord(Database db) =>
      rawRef.onSnapshot(db).map((snapshot) => snapshot?.cv<V>());

  /// Track changes
  Stream<List<V>> onRecords(Database db) =>
      rawRef.onSnapshots(db).map((snapshots) => snapshots.cv<V>());
}

/// Store factory interface
abstract class CvStoreFactory<K> {
  /// Creates a reference to a store.
  CvStoreRef<K, V> store<V extends DbRecord<K>>([String? name]);
}

/// Store factory base.
// class CvStoreFactoryBase<K> with CvStoreFactoryMixin<K> {}

/// common `<int, Map<String, Object?>>` factory
final cvIntRecordFactory = CvIntStoreFactory();

final cvStringRecordFactory = CvStringStoreFactory();

class CvIntStoreFactory extends CvStoreFactoryBase<int> {}

class CvStringStoreFactory extends CvStoreFactoryBase<String> {}

class CvStoreFactoryBase<K> with CvStoreFactoryMixin<K> {}
