import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/src/scv_record.dart';
import 'package:tekartik_app_cv_sdb/src/scv_record_db.dart';
import 'package:tekartik_common_utils/list_utils.dart';

/// Common DB helpers
extension ScvStoreRefDbExt<K extends SdbKey, V extends ScvRecord<K>>
    on ScvStoreRef<K, V> {
  /// Add
  Future<V> add(SdbClient db, V record) async {
    return db.scvHandleDbOrTxn<V>(
      (db) => dbAddImpl(db, record),
      (txn) => txnAddImpl(txn, record),
    );
  }

  /// Find records.
  Future<List<V>> findRecords(
    SdbClient client, {

    SdbBoundaries<K>? boundaries,

    /// Optional filter, performed in memory
    SdbFilter? filter,
    int? offset,
    int? limit,

    /// Optional sort order
    bool? descending,
  }) async {
    var snapshots = await rawRef.findRecords(
      client,
      boundaries: boundaries,
      filter: filter,
      offset: offset,
      limit: limit,
      descending: descending,
    );
    return snapshots.lazy((snapshot) => snapshot.cv());
  }

  /// Find records.
  Future<V?> findRecord(
    SdbClient client, {

    SdbBoundaries<K>? boundaries,

    /// Optional filter, performed in memory
    SdbFilter? filter,
    int? offset,

    /// Optional sort order
    bool? descending,
  }) async {
    var records = await findRecords(
      client,
      boundaries: boundaries,
      filter: filter,
      offset: offset,
      limit: 1,
      descending: descending,
    );
    return records.firstOrNull;
  }

  /// Delete records.
  Future<void> delete(
    SdbClient client, {
    SdbBoundaries<K>? boundaries,
    int? offset,
    int? limit,

    /// Optional sort order
    bool? descending,
  }) async {
    await rawRef.delete(
      client,
      boundaries: boundaries,
      offset: offset,
      limit: limit,
      descending: descending,
    );
  }

  /// Count records.
  Future<int> count(
    SdbClient client, {
    SdbBoundaries<K>? boundaries,
    int? offset,
    int? limit,

    /// Optional sort order
    bool? descending,
  }) {
    return rawRef.count(client, boundaries: boundaries);
  }
}

/// Internal DB helpers
extension ScvStoreRefDbExtInternal<K extends SdbKey, V extends ScvRecord<K>>
    on ScvStoreRef<K, V> {
  /// Add a single record.
  Future<V> dbAddImpl(SdbDatabase db, V record) {
    return db.inStoreTransaction<V, K, Model>(
      rawRef,
      SdbTransactionMode.readWrite,
      (txn) {
        return txnAddImpl(txn, record);
      },
    );
  }

  /// Add a single record.
  Future<V> txnAddImpl(SdbTransaction txn, V record) async {
    var store = txn.store(rawRef);
    var id = await store.add(record.toDbMap());
    record = record.scvClone()..ref = this.record(id);
    if (store.keyPath != null) {
      record.setKeyValue(store.keyPath, id);
    }
    return record;
  }
}
