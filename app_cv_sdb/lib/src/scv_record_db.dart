import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

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
  /// if [ifNotExists] is true, the record is only created if it does not exist.
  ///
  /// if [merge] is true and the record exists, data is merged
  ///
  /// Both [merge] and [ifNotExists] cannot be true at the same time.
  /// Returns the updated value or existing value if [ifNotExists] is true and
  /// the record exists
  Future<V> put(SdbClient db, V value, {bool? ifNotExists}) async {
    return db.scvHandleDbOrTxn<V>(
      (db) => dbPutImpl(db, value),
      (txn) => txnPutImpl(txn, value),
    );
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
    await txn.store(rawRef.store).put(key, value.toMap());
    return value;
  }
}

/// Easy extension
extension ScvRecordDbExt<K extends SdbKey, V> on ScvRecord<K> {
  /// put
  Future<void> put(SdbClient db) async {
    await rawRef.put(db, toMap());
    //fromMap(data);
  }

  /// delete
  Future<void> delete(SdbClient db) async {
    await rawRef.delete(db);
  }
}
