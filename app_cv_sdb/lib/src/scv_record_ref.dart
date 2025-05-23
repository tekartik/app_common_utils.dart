import 'package:cv/cv.dart';
import 'package:idb_shim/sdb/sdb.dart';

import 'scv_record.dart';
import 'scv_store_ref.dart';

/// Record reference
class ScvRecordRef<K extends SdbKey, V extends ScvRecord<K>> {
  /// Store
  final ScvStoreRef<K, V> store;

  /// Raw ref
  final SdbRecordRef<K, Model> rawRef;

  /// Constructor
  ScvRecordRef(this.store, K key) : rawRef = store.rawRef.record(key);

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ScvRecordRef(${store.name}, $key)';

  @override
  bool operator ==(Object other) {
    if (other is ScvRecordRef) {
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

/// String record ref
typedef ScvStringRecordRef<T extends ScvStringRecord> = ScvRecordRef<String, T>;

/// int record ref
typedef ScvIntRecordRef<T extends ScvIntRecord> = ScvRecordRef<int, T>;

/// Record reference extension
extension ScvRecordRefExt<K extends SdbKey, V extends ScvRecord<K>>
    on ScvRecordRef<K, V> {
  /// Key
  K get key => rawRef.key;

  /// To build for write
  V cv() => cvBuildModel<V>({})..rawRef = rawRef;

  /// Cast if needed
  ScvRecordRef<RK, RV> cast<RK extends SdbKey, RV extends ScvRecord<RK>>() {
    if (this is ScvRecordRef<RK, RV>) {
      return this as ScvRecordRef<RK, RV>;
    }
    return store.cast<RK, RV>().record(key as RK);
  }

  /// Cast if needed
  ScvRecordRef<K, RV> castV<RV extends ScvRecord<K>>() => cast<K, RV>();
}
