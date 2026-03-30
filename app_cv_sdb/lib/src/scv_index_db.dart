import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/src/scv_index_record.dart';
import 'package:tekartik_app_cv_sdb/src/scv_index_ref.dart';
import 'package:tekartik_common_utils/list_utils.dart';

import 'scv_index_record_ref.dart';

/// Index record reference extension db access.
extension ScvIndexRefDbExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRef<K, V, I> {
  /// Find records.
  Future<List<ScvIndexRecord<K, V, I>>> findRecords(
    SdbClient client, {
    SdbBoundaries<I>? boundaries,

    /// Optional filter, performed in memory
    SdbFilter? filter,
    int? offset,
    int? limit,

    /// Optional descending order
    bool? descending,

    /// New api
    SdbFindOptions<I>? options,
  }) async {
    var rawSnapshots = await impl.rawRef.findRecords(
      client,
      options: sdbFindOptionsMerge<I>(
        options,
        boundaries: boundaries,
        limit: limit,
        offset: offset,
        descending: descending,
        filter: filter,
      ),
    );
    return rawSnapshots.lazy(
      (rawSnapshot) =>
          _ScvIndexRecord(impl.record(rawSnapshot.indexKey), rawSnapshot),
    );
  }

  /// Stream records.
  Stream<ScvIndexRecord<K, V, I>> streamRecords(
    SdbClient client, {
    SdbBoundaries<I>? boundaries,

    /// Optional filter, performed in memory
    SdbFilter? filter,
    int? offset,
    int? limit,

    /// Optional descending order
    bool? descending,

    /// New api
    SdbFindOptions<I>? options,
  }) {
    return impl.rawRef
        .streamRecords(
          client,
          options: sdbFindOptionsMerge<I>(
            options,
            boundaries: boundaries,
            limit: limit,
            offset: offset,
            descending: descending,
            filter: filter,
          ),
        )
        .map(
          (rawSnapshot) =>
              _ScvIndexRecord(impl.record(rawSnapshot.indexKey), rawSnapshot),
        );
  }

  /// Find a single record.
  Future<ScvIndexRecord<K, V, I>?> findRecord(
    SdbClient client, {
    SdbBoundaries<I>? boundaries,

    /// Optional filter, performed in memory
    SdbFilter? filter,
    int? offset,

    /// Optional descending order
    bool? descending,

    /// New api
    SdbFindOptions<I>? options,
  }) async {
    var records = await findRecords(
      client,
      options: sdbFindOptionsMerge<I>(
        options,
        boundaries: boundaries,
        offset: offset,
        descending: descending,
        filter: filter,
      ).copyWith(limit: 1),
    );
    return records.firstOrNull;
  }

  /// Find record keys.
  Future<List<ScvIndexRecordKey<K, V, I>>> findRecordKeys(
    SdbClient client, {
    SdbBoundaries<I>? boundaries,
    int? offset,
    int? limit,

    /// Optional descending order
    bool? descending,

    /// New api
    SdbFindOptions<I>? options,
  }) async {
    var rawKeys = await impl.rawRef.findRecordKeys(
      client,
      options: sdbFindOptionsMerge<I>(
        options,
        boundaries: boundaries,
        limit: limit,
        offset: offset,
        descending: descending,
      ),
    );
    return rawKeys.lazy(
      (rawKey) =>
          _ScvIndexRecordKey<K, V, I>(impl.record(rawKey.indexKey), rawKey),
    );
  }

  /// Find a single record key.
  Future<ScvIndexRecordKey<K, V, I>?> findRecordKey(
    SdbClient client, {
    SdbBoundaries<I>? boundaries,
    int? offset,

    /// Optional descending order
    bool? descending,
  }) async {
    var keys = await findRecordKeys(
      client,
      boundaries: boundaries,
      limit: 1,
      offset: offset,
      descending: descending,
    );
    return keys.firstOrNull;
  }

  /// Count records.
  Future<int> count(SdbClient client, {SdbBoundaries<I>? boundaries}) async {
    return await impl.rawRef.count(client, boundaries: boundaries);
  }

  /// Delete records.
  Future<void> delete(
    SdbClient client, {
    SdbBoundaries<I>? boundaries,
    int? offset,
    int? limit,

    /// Optional descending order
    bool? descending,
  }) => impl.rawRef.delete(
    client,
    boundaries: boundaries,
    offset: offset,
    limit: limit,
    descending: descending,
  );

  /// Track changes
  Stream<List<ScvIndexRecord<K, V, I>>> onIndexRecords(
    SdbDatabase db, {
    SdbFindOptions<I>? options,
  }) async* {
    yield* impl.rawRef
        .onSnapshots(db, options: options)
        .map((snapshots) => makeIndexRecords(snapshots));
  }

  /// Track changes
  Stream<List<V>> onObjects(
    SdbDatabase db, {
    SdbFindOptions<I>? options,
  }) async* {
    yield* impl.rawRef
        .onSnapshots(db, options: options)
        .map((snapshots) => makeObjects(snapshots));
  }
}

class _ScvIndexRecordKey<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    implements ScvIndexRecordKey<K, V, I> {
  final ScvIndexRecordRef<K, V, I> _indexRecordRef;
  final ScvRecordRef<K, V> _recordRef;

  I get _indexKey => _indexRecordRef.indexKey;

  K get _key => _recordRef.key;
  _ScvIndexRecordKey(
    this._indexRecordRef,
    SdbIndexRecordKey<K, SdbModel, I> rawKey,
  ) : _recordRef = _indexRecordRef.store.record(rawKey.key);
}

class _ScvIndexRecord<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    extends _ScvIndexRecordKey<K, V, I>
    implements ScvIndexRecord<K, V, I> {
  late final V _record;

  _ScvIndexRecord(
    ScvIndexRecordRef<K, V, I> indexRecordRef,
    SdbIndexRecordSnapshot<K, SdbModel, I> rawSnapshot,
  ) : super(indexRecordRef, rawSnapshot) {
    _record = (cvBuildModel<V>(rawSnapshot.value)..ref = _recordRef)
      ..fromMap(rawSnapshot.value);
  }
  @override
  String toString() =>
      'IndexRecord(${_recordRef.store.name}, $key, $_indexKey)';
}

/// Index record reference extension db access.
extension ScvIndexRefInternalExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRef<K, V, I> {
  /// Single record
  ScvIndexRecord<K, V, I>? makeRecord(
    SdbIndexRecordSnapshot<K, SdbModel, I>? rawSnapshot,
  ) {
    if (rawSnapshot == null) {
      return null;
    }
    return _ScvIndexRecord<K, V, I>(record(rawSnapshot.indexKey), rawSnapshot);
  }

  /// Lazy list on index record object
  List<ScvIndexRecord<K, V, I>> makeIndexRecords(
    List<SdbIndexRecordSnapshot<K, SdbModel, I>> rawSnapshots,
  ) {
    return rawSnapshots.lazy(
      (snapshot) =>
          _ScvIndexRecord<K, V, I>(record(snapshot.indexKey), snapshot),
    );
  }

  /// Lazy list on index record object
  List<V> makeObjects(
    List<SdbIndexRecordSnapshot<K, SdbModel, I>> rawSnapshots,
  ) {
    return rawSnapshots.lazy((snapshot) => snapshot.cv<V>());
  }
}

/// Index record reference extension db access.
extension ScvIndexRecordRefInternalExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRecordRef<K, V, I> {
  /// Single record
  ScvIndexRecord<K, V, I>? makeRecord(
    SdbIndexRecordSnapshot<K, SdbModel, I>? rawSnapshot,
  ) {
    if (rawSnapshot == null) {
      return null;
    }
    return _ScvIndexRecord<K, V, I>(this, rawSnapshot);
  }

  /// Lazy list on index record object
  List<ScvIndexRecord<K, V, I>> makeIndexRecords(
    List<SdbIndexRecordSnapshot<K, SdbModel, I>> rawSnapshots,
  ) {
    return rawSnapshots.lazy(
      (snapshot) => _ScvIndexRecord<K, V, I>(this, snapshot),
    );
  }

  /// Lazy list on index record object
  List<V> makeObjects(
    List<SdbIndexRecordSnapshot<K, SdbModel, I>> rawSnapshots,
  ) {
    return rawSnapshots.lazy((snapshot) => snapshot.cv<V>());
  }
}

extension _ScvIndexRecordKeyExtPrv<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRecordKey<K, V, I> {
  _ScvIndexRecordKey<K, V, I> get keyImpl =>
      this as _ScvIndexRecordKey<K, V, I>;
}

/// Index record key extension.
extension ScvIndexRecordKeyExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRecordKey<K, V, I> {
  /// Store reference.
  ScvStoreRef<K, V> get store => keyImpl._indexRecordRef.store;

  /// Index reference.
  ScvIndexRef<K, V, I> get index => keyImpl._indexRecordRef.index;

  /// The primary key
  K get key => keyImpl._key;

  /// The index key
  I get indexKey => keyImpl._indexKey;
}

extension _ScvIndexRecordExtPrv<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRecord<K, V, I> {
  _ScvIndexRecord<K, V, I> get impl => this as _ScvIndexRecord<K, V, I>;
}

/// Index record extension.
extension ScvIndexRecordExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRecord<K, V, I> {
  /// The record
  V get record => impl._record;
}
