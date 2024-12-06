import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

/// Helpers
extension TekartikDbRecordListCvExt<T extends DbRecord<K>, K> on List<T> {
  /// Convert to a map
  Map<K, T> toMap() {
    var map = <K, T>{for (var document in this) document.id: document};
    return map;
  }
}
