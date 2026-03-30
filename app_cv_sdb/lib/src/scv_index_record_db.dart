import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/src/scv_index_db.dart';

/// Index record reference extension db access.
extension ScvIndexRecordRefDbExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRecordRef<K, V, I> {
  /// Get a single record.
  Future<ScvIndexRecord<K, V, I>?> get(SdbClient client) async {
    var rawSnapshot = await impl.rawRef.get(client);
    return makeRecord(rawSnapshot);
  }

  /// Get a single record key.
  Future<K?> getKey(SdbClient client) async {
    var key = await impl.rawRef.getKey(client);
    return key;
  }

  /// Get a single record.
  Future<V?> getObject(SdbClient client) async {
    return (await get(client))?.record;
  }

  /// Find records.
  Future<List<ScvIndexRecord<K, V, I>>> findRecords(
    SdbClient client, {
    SdbFindOptions<I>? options,
  }) async {
    var rawSnapshots = await impl.rawRef.findRecords(client, options: options);
    return index.makeIndexRecords(rawSnapshots);
  }

  /// Find records.
  Future<List<K>> findRecordPrimaryKeys(
    SdbClient client, {
    SdbFindOptions<I>? options,
  }) async {
    return (await impl.rawRef.findRecordKeys(client, options: options)).keys;
  }

  /// Find objects.
  Future<List<V>> findObjects(
    SdbClient client, {
    SdbFindOptions<I>? options,
  }) async {
    var rawSnapshots = await impl.rawRef.findRecords(client, options: options);
    return makeObjects(rawSnapshots);
  }

  /// Find objects.
  Future<V?> findObject(SdbClient client, {SdbFindOptions<I>? options}) async {
    var rawSnapshot = await findRecord(client, options: options);
    return rawSnapshot?.record;
  }

  /// Find records.
  Future<ScvIndexRecord<K, V, I>?> findRecord(
    SdbClient client, {
    SdbFindOptions<I>? options,
  }) {
    options = sdbFindOptionsMerge(options).copyWith(limit: 1);
    return findRecords(
      client,
      options: options,
    ).then((records) => records.firstOrNull);
  }

  /// Count records.
  Future<int> count(SdbClient client, {SdbFindOptions<I>? options}) async {
    return await impl.rawRef.count(client, options: options);
  }

  /// Delete record with the given index key.
  /// Multiple record could be deleted
  Future<void> delete(SdbClient client, {SdbFindOptions<I>? options}) async {
    await impl.rawRef.delete(client, options: options);
  }

  /// Track changes
  @Deprecated('Use on IndexRecord instead')
  Stream<ScvIndexRecord<K, V, I>?> onRecord(SdbDatabase db) =>
      onIndexRecord(db);

  /// Track changes
  Stream<ScvIndexRecord<K, V, I>?> onIndexRecord(SdbDatabase db) {
    return impl.rawRef.onSnapshot(db).map((snapshot) => makeRecord(snapshot));
  }

  /// Track changes
  Stream<V?> onObject(SdbDatabase db) {
    return onIndexRecord(db).map((record) => record?.record);
  }

  /// Track changes
  @Deprecated('use on IndexRecords instead')
  Stream<List<ScvIndexRecord<K, V, I>>> onRecords(
    SdbDatabase db, {
    SdbFindOptions<I>? options,
  }) => onIndexRecords(db, options: options);

  /// Track changes
  Stream<List<ScvIndexRecord<K, V, I>>> onIndexRecords(
    SdbDatabase db, {
    SdbFindOptions<I>? options,
  }) {
    return impl.rawRef
        .onSnapshots(db, options: options)
        .map((snapshot) => index.makeIndexRecords(snapshot));
  }

  /// Track changes
  Stream<List<V>> onObjects(SdbDatabase db, {SdbFindOptions<I>? options}) {
    return impl.rawRef
        .onSnapshots(db, options: options)
        .map((list) => index.makeObjects(list));
  }
}

/// Private extension to access the implementation.
extension ScvIndexRecordRefExtPrv<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRecordRef<K, V, I> {
  /// Store reference.
  ScvIndexRecordRefImpl<K, V, I> get impl =>
      this as ScvIndexRecordRefImpl<K, V, I>;
}

/// Index record reference implementation.
class ScvIndexRecordRefImpl<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    implements ScvIndexRecordRef<K, V, I> {
  /// Raw reference.
  final SdbIndexRecordRef<K, SdbModel, I> rawRef;
  @override
  final ScvIndexRef<K, V, I> index;

  /// Index record reference implementation.
  ScvIndexRecordRefImpl(this.index, this.rawRef);
}
