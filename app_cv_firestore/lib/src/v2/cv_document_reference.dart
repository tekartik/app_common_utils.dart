import 'package:cv/cv.dart';
import 'package:path/path.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore_v2.dart';
import 'package:tekartik_app_cv_firestore/src/v2/cv_path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Document helper
class CvDocumentReference<T extends CvFirestoreDocument>
    with CvPathReferenceMixin {
  /// Document path
  @override
  final String path;

  CvDocumentReference(this.path);

  Type get type => T;

  /// Get a document
  Future<T> get(Firestore firestore) => firestore.doc(path).cvGet<T>();

  /// Set a document.
  Future<void> setMap(Firestore firestore, Model map, [SetOptions? options]) =>
      firestore.doc(path).set(map, options);

  /// Set a document. document path is ignored here.
  Future<void> set(Firestore firestore, T document, [SetOptions? options]) =>
      setMap(firestore, document.toMap(), options);

  /// Update a document.
  Future<void> updateMap(Firestore firestore, Model map) =>
      firestore.doc(path).update(map);

  /// Update a document. document path is ignored here.
  Future<void> update(Firestore firestore, T document) =>
      updateMap(firestore, document.toMap());

  /// Document changed
  Stream<T> onSnapshot(Firestore firestore) =>
      firestore.doc(path).cvOnSnapshot();

  T cv() => cvBuildModel<T>({})
    ..path = path
    // ignore: invalid_use_of_visible_for_testing_member
    ..exists = false;

  T cvType(Type type) => cvTypeBuildModel<T>(type, {})
    ..path = path
    // ignore: invalid_use_of_visible_for_testing_member
    ..exists = false;

  /// Delete
  Future<void> delete(Firestore firestore) => firestore.doc(path).delete();

  /// Sub collection reference (different type!)
  CvCollectionReference<U> collection<U extends CvFirestoreDocument>(
          String path) =>
      CvCollectionReference<U>(url.join(this.path, path));

  /// Raw document reference
  DocumentReference raw(Firestore firestore) => firestore.doc(path);

  @override
  String toString() => 'CvDocumentReference<$T>($path)';
}

/// Document reference helpers.
extension DocumentReferenceCvExtension on DocumentReference {
  /// Convert from raw reference.
  CvDocumentReference<T> cv<T extends CvFirestoreDocument>() =>
      CvDocumentReference<T>(path);
}
