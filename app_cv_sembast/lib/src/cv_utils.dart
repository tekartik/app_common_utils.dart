import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

/// Helpers
extension TekartikDbStringRecordListCvExt<T extends DbStringRecord> on List<T> {
  /// Convert to a map
  Map<String, T> toMap() {
    var map = <String, T>{for (var document in this) document.id: document};
    return map;
  }
}

/// Helpers
extension TekartikDbIntRecordListCvExt<T extends DbIntRecord> on List<T> {
  /// Convert to a map
  Map<int, T> toMap() {
    var map = <int, T>{for (var document in this) document.id: document};
    return map;
  }
}
