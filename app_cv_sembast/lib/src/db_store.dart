import 'cv_store_ref.dart';
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

/// Store factory interface
abstract class CvStoreFactory<K> {
  /// Creates a reference to a store.
  CvStoreRef<K, V> store<V extends DbRecord<K>>([String? name]);
}

/// Store factory base.
// class CvStoreFactoryBase<K> with CvStoreFactoryMixin<K> {}

/// common `<int, Map<String, Object?>>` factory
@Deprecated('Use cvIntStoreFactory instead')
final cvIntRecordFactory = cvIntStoreFactory;

/// common `<String, Map<String, Object?>>` factory
@Deprecated('Use cvStringStoreFactory instead')
final cvStringRecordFactory = cvStringStoreFactory;

/// common `<int, Map<String, Object?>>` factory
final cvIntStoreFactory = CvIntStoreFactory();

/// common `<String, Map<String, Object?>>` factory
final cvStringStoreFactory = CvStringStoreFactory();

/// Store with int key
class CvIntStoreFactory extends CvStoreFactoryBase<int> {}

/// Store with string key
class CvStringStoreFactory extends CvStoreFactoryBase<String> {}

/// Store factory base.
class CvStoreFactoryBase<K> with CvStoreFactoryMixin<K> {}
