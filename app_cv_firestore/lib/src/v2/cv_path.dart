import 'package:path/path.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_app_cv_firestore/src/import_firestore.dart';

abstract class CvPathReference<T> {
  String get path;
}

mixin CvPathReferenceMixin<T> implements CvPathReference<T> {
  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is CvPathReference) {
      return path == other.path;
    }
    return false;
  }

  /// Id
  String get id => url.basename(path);
}

extension CvFirestorePathExtension on String {
  CvCollectionReference<T> parentColl<T extends CvFirestoreDocument>() {
    return CvCollectionReference<T>(firestorePathGetParent(this)!);
  }

  CvDocumentReference<T>? parentDocOrNull<T extends CvFirestoreDocument>() {
    var parentPath = firestorePathGetParent(this);
    if (parentPath == null) {
      return null;
    }
    return CvDocumentReference<T>(parentPath);
  }
}

extension CvFirestorePathOrNullExtension on String? {}
