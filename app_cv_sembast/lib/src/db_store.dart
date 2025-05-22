import 'package:sembast/sembast.dart';

import 'cv_store_ref.dart';
import 'db_record.dart';

/// Store factory mixin.
mixin CvStoreFactoryMixin<K extends RecordKeyBase>
    implements DbStoreFactory<K> {
  @override
  CvStoreRef<K, V> store<V extends DbRecord<K>>([String? name]) {
    if (name == null) {
      return CvStoreRef<K, V>.main();
    } else {
      return CvStoreRef<K, V>(name);
    }
  }
}

/// Compat.
typedef CvStoreFactory<K extends RecordKeyBase> = DbStoreFactory<K>;

/// Store factory interface
abstract class DbStoreFactory<K extends RecordKeyBase> {
  /// Creates a reference to a store.
  CvStoreRef<K, V> store<V extends DbRecord<K>>([String? name]);
}

/// Store factory base.
// class CvStoreFactoryBase<K> with CvStoreFactoryMixin<K> {}

/// common `<int, Map<String, Object?>>` factory
@Deprecated('Use cvIntStoreFactory instead')
final cvIntRecordFactory = dbIntStoreFactory;

/// common `<String, Map<String, Object?>>` factory
@Deprecated('Use cvStringStoreFactory instead')
final cvStringRecordFactory = dbStringStoreFactory;

/// common `<int, DbRecord<int>` factory
final DbStoreFactory<int> dbIntStoreFactory = DbIntStoreFactory();

/// Compat
final cvIntStoreFactory = dbIntStoreFactory;

/// common `<String, DbRecord<String>` factory
final DbStoreFactory<String> dbStringStoreFactory = DbStringStoreFactory();

/// Compat
final cvStringStoreFactory = dbStringStoreFactory;

/// Store with int key
class DbIntStoreFactory extends DbStoreFactoryBase<int> {}

/// Compat
typedef CvIntStoreFactory = DbIntStoreFactory;

/// Store with string key
class DbStringStoreFactory extends DbStoreFactoryBase<String> {}

/// Compat
typedef CvStringStoreFactory = DbStringStoreFactory;

/// Store factory base.
class DbStoreFactoryBase<K extends RecordKeyBase> with CvStoreFactoryMixin<K> {}
