import 'scv_record.dart';

/// Helpers
extension TekartikScvStringRecordListCvExt<T extends ScvStringRecord>
    on List<T> {
  /// Convert to a map
  Map<String, T> toMap() {
    var map = <String, T>{for (var document in this) document.id: document};
    return map;
  }
}

/// Helpers
extension TekartikScvIntRecordListCvExt<T extends ScvIntRecord> on List<T> {
  /// Convert to a map
  Map<int, T> toMap() {
    var map = <int, T>{for (var document in this) document.id: document};
    return map;
  }
}
