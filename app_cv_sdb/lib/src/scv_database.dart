import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/src/scv_index_ref.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

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

/// Store reference open helper.
extension ScvOpenStoreRefExt<K extends SdbKey, V extends ScvRecord<K>>
    on ScvOpenStoreRef<K, V> {
  /// Create an index.
  ScvOpenIndexRef<K, V, I> createIndex<I extends SdbIndexKey>(
    ScvIndex1Ref<K, V, I> index,
    String indexKeyPath,
  ) => _ScvOpenIndexRef<K, V, I>(
    _impl,
    _impl.store.createIndex<I>(index.rawRef1, indexKeyPath),
  );
}

/// Private extension to access the implementation.
extension ScvOpenStoreRefExtPrv<K extends SdbKey, V extends ScvRecord<K>>
    on ScvOpenStoreRef<K, V> {
  /// Get the implementation.
  _ScvOpenStoreRef<K, V> get _impl => this as _ScvOpenStoreRef<K, V>;
}

/// Open index reference.
abstract class ScvOpenIndexRef<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
> {}

class _ScvOpenIndexRef<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    implements ScvOpenIndexRef<K, V, I> {
  final ScvOpenStoreRef<K, V> store;
  final SdbOpenIndexRef<K, Model, I> rawRef;

  _ScvOpenIndexRef(this.store, this.rawRef);
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

/// Common helper on database
extension ScvDatabaseExtension on SdbDatabase {
  /// Run a transaction.
  Future<T> inScvStoresTransaction<T, K extends SdbKey, V extends SdbValue>(
    List<ScvStoreRef> stores,
    SdbTransactionMode mode,
    FutureOr<T> Function(SdbMultiStoreTransaction txn) callback,
  ) {
    return inStoresTransaction(
      stores.map((item) => item.rawRef).toList(),
      mode,
      callback,
    );
  }
}
