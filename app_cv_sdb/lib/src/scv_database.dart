import 'package:cv/cv.dart';
import 'package:idb_shim/sdb.dart';
import 'scv_record.dart';
import 'scv_store_ref.dart';

/// Open store reference.
abstract class ScvOpenStoreRef<K extends SdbKey, V extends ScvRecord<K>> {}

class _ScvOpenStoreRef<K extends SdbKey, V extends ScvRecord<K>>
    implements ScvOpenStoreRef<K, V> {
  // ignore: unused_field
  final SdbOpenDatabase _database;

  /// Store reference.
  final SdbOpenStoreRef<K, Model> store;

  _ScvOpenStoreRef(this._database, this.store);
}

/// Helper
extension ScvOpenDatabaseExt on SdbOpenDatabase {
  /// Create a store.
  /// auto increment is set to true if not set for int keys
  ScvOpenStoreRef<K, V> scvCreateStore<
    K extends SdbKey,
    V extends ScvRecord<K>
  >(ScvStoreRef<K, V> store, {String? keyPath, bool? autoIncrement}) {
    var openStore = createStore<K, Model>(
      store.rawRef,
      keyPath: keyPath,
      autoIncrement: autoIncrement,
    );
    return _ScvOpenStoreRef<K, V>(this, openStore);
  }
}
