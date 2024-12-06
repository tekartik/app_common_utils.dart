import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

/// Helpers
extension TekartikCvFirestoreCvDocumentListCvExt<T extends CvFirestoreDocument>
    on List<T> {
  /// Convert to a map
  Map<String, T> toMap() {
    var map = <String, T>{for (var document in this) document.id: document};
    return map;
  }

  List<Model> toInfoJsonList() {
    return map((document) => document.toInfoJson()).toList();
  }
}
