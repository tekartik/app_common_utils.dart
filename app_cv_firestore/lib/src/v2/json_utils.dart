import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';

/// info json list to document list
T infoJsonToDocument<T extends CvFirestoreDocument>(Model infoJson) {
  var docInfo = FirestoreDocumentInfo.fromJsonMap(infoJson);
  var doc = docInfo.data.asMap().cv<T>()..path = docInfo.path;
  return doc;
}

/// info json list to document list
List<T> infoJsonListToDocumentList<T extends CvFirestoreDocument>(
    List<Model> infoJsonList) {
  return infoJsonList
      .map((infoJson) => infoJsonToDocument<T>(infoJson))
      .toList();
}

/// Helpers
extension TekartikCvFirestoreDocumentSnapshotListInfoJsonListExt
    on List<DocumentSnapshot> {
  List<Model> toInfoJsonList() {
    return map((snapshot) =>
            FirestoreDocumentInfo.fromDocumentSnapshot(snapshot).toJsonMap())
        .toList();
  }
}

/// Helpers
extension TekartikCvFirestoreCvDocumentInfoJsonExt on CvFirestoreDocument {
  Model toInfoJson() {
    return FirestoreDocumentInfo(path: ref.path, data: DocumentData(toMap()))
        .toJsonMap();
  }
}

/// Helpers
extension TekartikCvFirestoreCvDocumentListInfoJsonListExt
    on List<CvFirestoreDocument> {
  List<Model> toInfoJsonList() {
    return map((document) => document.toInfoJson()).toList();
  }
}
