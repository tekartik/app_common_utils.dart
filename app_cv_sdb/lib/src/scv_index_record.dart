import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

/// Easy extension
extension ScvIndexRecordSnapshotCvInternalExt<
  K extends SdbKey,
  I extends SdbIndexKey
>
    on SdbIndexRecordSnapshot<K, SdbModel, I> {
  /// Create a DbRecord from a snapshot
  V cv<V extends ScvRecord<K>>() {
    return value.cv<V>()..rawRef = store.record(key);
  }
}
