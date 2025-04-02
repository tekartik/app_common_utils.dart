import 'package:path/path.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore_v2.dart';
import 'package:tekartik_app_cv_firestore/src/v2/cv_document.dart'
    show CvFirestoreDocumentPrvExt;
import 'package:tekartik_app_cv_firestore/src/v2/cv_path.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';

/// Document helper
class CvDocumentReference<T extends CvFirestoreDocument>
    with CvPathReferenceMixin {
  /// Document path
  @override
  final String path;

  CvDocumentReference(this.path);

  CvCollectionReference<T> get parent => path.parentColl<T>();

  //String get genericPath => parent.parent.url.basename(path);

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

  /// Document changed
  Stream<T> onSnapshotSupport(
    Firestore firestore, {
    TrackChangesPullOptions? options,
  }) => firestore.doc(path).cvOnSnapshotSupport(options: options);

  T cv() =>
      cvBuildModel<T>({})
        ..path = path
        // ignore: invalid_use_of_visible_for_testing_member
        ..prvExists = false;

  T cvType(Type type) =>
      cvTypeBuildModel<T>(type, {})
        ..path = path
        // ignore: invalid_use_of_visible_for_testing_member
        ..prvExists = false;

  /// Delete
  Future<void> delete(Firestore firestore) => firestore.doc(path).delete();

  /// Sub collection reference (different type!)
  CvCollectionReference<U> collection<U extends CvFirestoreDocument>(
    String path,
  ) => CvCollectionReference<U>(url.join(this.path, path));

  /// Raw document reference
  DocumentReference raw(Firestore firestore) => firestore.doc(path);

  /// New path, same type to a different type
  CvDocumentReference<T> withPath(String path) => CvDocumentReference<T>(path);

  /// New path, same type to a different type
  CvDocumentReference<T> withId(String id) =>
      CvDocumentReference<T>(firestorePathReplaceId(path, id));
  @override
  String toString() => 'CvDocumentReference<$T>($path)';
}

/// Document reference helpers.
extension DocumentReferenceCvExtension on DocumentReference {
  /// Convert from raw reference.
  CvDocumentReference<T> cv<T extends CvFirestoreDocument>() =>
      CvDocumentReference<T>(path);
}

/// CvDocumentReference helpers.
extension CvDocumentReferenceExtension<T extends CvFirestoreDocument>
    on CvDocumentReference<T> {
  /// Parent
  CvCollectionReference<T> get parent => path.parentColl<T>();
}

/// Root reference
final cvRootDocumentReference = CvDocumentReference<CvFirestoreDocument>('');
