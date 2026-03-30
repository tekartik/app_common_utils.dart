import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';
import 'package:tekartik_app_cv_sdb/src/scv_index_record_db.dart';

/// Index record key.
abstract class ScvIndexRecordKey<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
> {}

/// Index record snapshot.
abstract class ScvIndexRecord<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    implements ScvIndexRecordKey<K, V, I> {}

/// Index reference.
/// Index record reference.
abstract class ScvIndexRecordRef<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
> {
  /// Index reference.
  ScvIndexRef<K, V, I> get index;
}

/// Index record reference extension.
extension ScvIndexRecordRefExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRecordRef<K, V, I> {
  /// Store reference.
  ScvStoreRef<K, V> get store => index.store;

  /// Get index key.
  I get indexKey => impl.rawRef.indexKey;
}
