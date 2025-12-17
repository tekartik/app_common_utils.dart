import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/src/scv_record.dart';
import 'package:tekartik_app_cv_sdb/src/scv_record_db.dart';

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

    /// New api
    SdbFindOptions<K>? options,
  }) async {
    var snapshots = await rawRef.findRecords(
      client,
      options: sdbFindOptionsMerge(
        options,
        boundaries: boundaries,
        filter: filter,
        offset: offset,
        limit: limit,
        descending: descending,
      ),
    );
    return snapshots.cv();
  }

  /// Find records.
  Stream<V> streamRecords(SdbClient client, {SdbFindOptions<K>? options}) {
    return rawRef.streamRecords(client, options: options).map((snapshot) {
      return snapshot.cv();
    });
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

    /// New api
    SdbFindOptions<K>? options,
  }) async {
    var records = await findRecords(
      client,
      options: sdbFindOptionsMerge(
        options,
        boundaries: boundaries,
        filter: filter,
        offset: offset,
        descending: descending,
      ).copyWith(limit: 1),
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
    SdbFindOptions<K>? options,
  }) {
    return rawRef.count(
      client,
      boundaries: boundaries,
      options: sdbFindOptionsMerge(
        options,
        offset: offset,
        limit: limit,
        descending: descending,
      ),
    );
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
