import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

import 'scv_index_ref.dart';
import 'scv_record.dart';

/// Store helper
class ScvStoreRef<K extends SdbKey, V extends ScvRecord<K>> {
  /// Raw ref
  final SdbStoreRef<K, Map<String, Object?>> rawRef;

  /// Constructor
  ScvStoreRef(String name)
    : rawRef = SdbStoreRef<K, Map<String, Object?>>(name);

  @override
  String toString() => 'ScvStoreRef($name)';

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is ScvStoreRef) {
      if (other.name != name) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Int store key
typedef ScvIntStoreRef<V extends ScvIntRecord> = ScvStoreRef<int, V>;

/// String store key
typedef ScvStringStoreRef<V extends ScvStringRecord> = ScvStoreRef<String, V>;

/// Common helpers
extension ScvStoreRefExt<K extends SdbKey, V extends ScvRecord<K>>
    on ScvStoreRef<K, V> {
  /// Name
  String get name => rawRef.name;

  /// Record ref
  ScvRecordRef<K, V> record(K key) => ScvRecordRef<K, V>(this, key);

  /// Index reference on 1 field
  ScvIndex1Ref<K, V, I> index<I extends SdbIndexKey>(String name) =>
      ScvIndex1RefImpl<K, V, I>(this, rawRef.index(name));

  /// Cast if needed
  ScvStoreRef<RK, RV> cast<RK extends SdbKey, RV extends ScvRecord<RK>>() {
    if (this is ScvStoreRef<RK, RV>) {
      return this as ScvStoreRef<RK, RV>;
    }
    return ScvStoreRef<RK, RV>(name);
  }

  /// Cast if needed
  ScvStoreRef<K, RV> castV<RV extends ScvRecord<K>>() => cast<K, RV>();

  /// Schema
  SdbStoreSchema schema({
    SdbKeyPath? keyPath,
    bool? autoIncrement,
    List<SdbIndexSchema>? indexes,
  }) {
    return rawRef.schema(
      keyPath: keyPath,
      autoIncrement: autoIncrement,
      indexes: indexes,
    );
  }
}

/// Store factory interface
abstract class ScvStoreFactory<K extends SdbKey> {
  /// Creates a reference to a store.
  ScvStoreRef<K, V> store<V extends ScvRecord<K>>(String name);
}

/// Store with int key
class ScvIntStoreFactory extends ScvStoreFactoryBase<int> {}

/// Store with string key
class ScvStringStoreFactory extends ScvStoreFactoryBase<String> {}

/// Store factory base.
class ScvStoreFactoryBase<K extends SdbKey> implements ScvStoreFactory<K> {
  @override
  ScvStoreRef<K, V> store<V extends ScvRecord<K>>(String name) {
    return ScvStoreRef<K, V>(name);
  }
}

/// Global Store ref factory
ScvStoreRef<K, V> scvStoreRef<K extends SdbKey, V extends ScvRecord<K>>(
  String name,
) {
  return ScvStoreRef<K, V>(name);
}

/// common `<int, DbRecord<int>` factory
final ScvStoreFactory<int> scvIntStoreFactory = ScvIntStoreFactory();

/// common `<String, DbRecord<String>` factory
final ScvStoreFactory<String> scvStringStoreFactory = ScvStringStoreFactory();
