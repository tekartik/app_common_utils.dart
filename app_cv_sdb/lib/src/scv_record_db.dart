import 'package:idb_shim/utils/idb_value_utils.dart';
import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/src/scv_record.dart';

/// Internal interface
extension ScvClientInternalExt on SdbClient {
  /// Handle db or transaction.
  Future<T> scvHandleDbOrTxn<T>(
    Future<T> Function(SdbDatabase db) dbFn,
    Future<T> Function(SdbTransaction txn) txnFn,
  ) {
    if (this is SdbTransaction) {
      return txnFn(this as SdbTransaction);
    } else {
      return dbFn(this as SdbDatabase);
    }
  }

  /// Handle db or transaction.
  Future<T> scvHandleStoreDbOrTxn<T>(
    ScvStoreRef storeRef,
    SdbTransactionMode mode,
    Future<T> Function(SdbTransaction txn) txnFn,
  ) {
    return scvHandleDbOrTxn<T>(
      (db) => storeRef.inTransaction(db, mode, txnFn),
      (txn) => txnFn(txn),
    );
  }
}

/// Helper extension.
extension ScvRecordRefDbExt<K extends SdbKey, V extends ScvRecord<K>>
    on ScvRecordRef<K, V> {
  /// Get
  Future<V?> get(SdbClient db) async => (await rawRef.get(db))?.cv<V>();

  /// Exists
  Future<bool> exists(SdbClient db) async => await rawRef.exists(db);

  /// Save a record, create if needed.
  ///
  /// Returns the updated value
  Future<V> put(SdbClient db, V value) async {
    return db.scvHandleDbOrTxn<V>(
      (db) => dbPutImpl(db, value),
      (txn) => txnPutImpl(txn, value),
    );
  }

  /// Add a record, throw if existing.
  ///
  /// Returns the inserted record
  Future<V> add(SdbClient db, V value) async {
    return db.scvHandleDbOrTxn<V>(
      (db) => dbAddImpl(db, value),
      (txn) => txnAddImpl(txn, value),
    );
  }

  /// Delete a record
  Future<void> delete(SdbClient client) async {
    await rawRef.delete(client);
  }
}

/// Helper extension.
extension ScvRecordRefDbExtInternal<K extends SdbKey, V extends ScvRecord<K>>
    on ScvRecordRef<K, V> {
  /// Put a single record.
  Future<V> dbPutImpl(SdbDatabase db, V value) {
    return db.inStoreTransaction(rawRef.store, SdbTransactionMode.readWrite, (
      txn,
    ) {
      return txnPutImpl(txn, value);
    });
  }

  /// Put a single record.
  Future<V> txnPutImpl(SdbTransaction txn, V value) async {
    await txn.store(rawRef.store).put(key, value.toDbMap());
    var record = value.scvClone()..ref = this;
    return record;
  }

  /// Add a single record.
  Future<V> dbAddImpl(SdbDatabase db, V value) {
    return db.inStoreTransaction(rawRef.store, SdbTransactionMode.readWrite, (
      txn,
    ) {
      return txnAddImpl(txn, value);
    });
  }

  /// Add a single record.
  Future<V> txnAddImpl(SdbTransaction txn, V value) async {
    var store = txn.store(rawRef.store);
    if (await store.exists(key)) {
      throw StateError('Record already exists');
    }
    await store.put(key, value.toDbMap());
    var record = value.scvClone()..ref = this;
    return record;
  }
}

/// Easy extension
extension ScvRecordDbExt<K extends SdbKey, V> on ScvRecord<K> {
  /// put
  Future<void> put(SdbClient db) async {
    await rawRef.put(db, toMap());
    //fromMap(data);
  }

  /// Update inner data.
  ///
  /// return true if updated, false if not (missing)
  Future<bool> update(SdbClient db, {Model? value}) async {
    return db.scvHandleDbOrTxn<bool>(
      (db) => dbUpdateImpl(db, value: value),
      (txn) => txnUpdateImpl(txn, value: value),
    );
  }

  /// Update inner data.
  ///
  /// return true if added, false if not (already exists)
  Future<bool> add(SdbClient db, {Model? value}) async {
    return db.scvHandleDbOrTxn<bool>(
      (db) => dbAddImpl(db, value: value),
      (txn) => txnAddImpl(txn, value: value),
    );
  }

  /// Delete record
  ///
  /// return true if deleted, false if not (missing)
  Future<bool> delete(SdbClient db) async {
    return db.scvHandleDbOrTxn<bool>(
      (db) => dbDeleteImpl(db),
      (txn) => txnDeleteImpl(txn),
    );
  }
}

/// Private extension
extension ScvRecordDbExtInternal<K extends SdbKey> on ScvRecord<K> {
  K? _idOrNull(
    SdbTransaction txn, {
    SdbTransactionStoreRef<K, Model>? store,
    Model? value,
  }) {
    value ??= toDbMap();
    store ??= txn.store(rawRef.store);
    var keyPath = store.keyPath;
    if (keyPath == null) {
      return idOrNull;
    }
    return idOrNull ?? (value.getKeyValue(keyPath) as K?);
  }

  /// Add a single record.
  Future<bool> dbAddImpl(SdbDatabase db, {Model? value}) {
    return db.inStoreTransaction(rawRef.store, SdbTransactionMode.readWrite, (
      txn,
    ) {
      return txnAddImpl(txn, value: value);
    });
  }

  /// Add a single record.
  Future<bool> txnAddImpl(SdbTransaction txn, {Model? value}) async {
    var addedValue = value ?? toDbMap();
    var store = txn.store(rawRef.store);
    var id = _idOrNull(txn, store: store, value: addedValue);

    Future<bool> add() async {
      var id = await store.add(addedValue);
      fromMap(addedValue);
      this.id = id;
      return true;
    }

    if (id == null) {
      return await add();
    }
    var exists = await store.exists(id);
    if (exists) {
      return false;
    }
    return add();
  }

  /// Put a single record.
  Future<bool> dbUpdateImpl(SdbDatabase db, {Model? value}) {
    return db.inStoreTransaction(rawRef.store, SdbTransactionMode.readWrite, (
      txn,
    ) {
      return txnUpdateImpl(txn, value: value);
    });
  }

  /// Put a single record.
  Future<bool> txnUpdateImpl(SdbTransaction txn, {Model? value}) async {
    value ??= toDbMap();
    var id = _idOrNull(txn, value: value);
    if (id == null) {
      throw StateError('Missing id');
    }
    var exists = await txn.store(rawRef.store).exists(id);
    if (!exists) {
      return false;
    }
    await txn.store(rawRef.store).put(id, value);
    return true;
  }

  /// Delete a single record.
  Future<bool> dbDeleteImpl(SdbDatabase db, {Model? value}) {
    return db.inStoreTransaction(rawRef.store, SdbTransactionMode.readWrite, (
      txn,
    ) {
      return txnDeleteImpl(txn, value: value);
    });
  }

  /// Delete a single record.
  Future<bool> txnDeleteImpl(SdbTransaction txn, {Model? value}) async {
    value ??= toDbMap();
    var exists = await txn.store(rawRef.store).exists(id);
    if (!exists) {
      return false;
    }
    await txn.store(rawRef.store).delete(id);
    return true;
  }
}

/// Easy extension
extension ScvRecordListDbExt<K extends SdbKey, V> on List<ScvRecord<K>> {
  /// put
  Future<void> put(SdbClient client) {
    if (isEmpty) return Future.value();

    return client.scvHandleStoreDbOrTxn(
      first.ref.store,
      SdbTransactionMode.readWrite,
      (txn) async {
        for (var record in this) {
          await record.put(txn);
        }
      },
    );
  }

  /// delete
  Future<void> delete(SdbClient client) {
    if (isEmpty) return Future.value();

    return client.scvHandleStoreDbOrTxn(
      first.ref.store,
      SdbTransactionMode.readWrite,
      (txn) async {
        var futures = <Future>[];
        for (var record in this) {
          futures.add(record.delete(txn));
        }
        await Future.wait(futures);
      },
    );
  }
}
