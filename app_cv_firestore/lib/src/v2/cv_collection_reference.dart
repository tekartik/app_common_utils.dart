import 'package:path/path.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore_v2.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';

import 'cv_path.dart';

/// Collection helper
class CvCollectionReference<T extends CvFirestoreDocument>
    with CvPathReferenceMixin {
  @override
  final String path;

  CvCollectionReference(this.path);

  Type get type => T;

  CvDocumentReference<T>? get parent => path.parentDocOrNull<T>();

  /// Get a list of document
  Future<int> count(Firestore firestore) => firestore.collection(path).count();

  /// Document reference
  CvDocumentReference<T> doc(String path) =>
      CvDocumentReference<T>(url.join(this.path, path));

  /// Create a query
  CvQueryReference<T> query() => CvQueryReference(this);

  /// Add a document, path in document is ignored
  Future<T> add(Firestore firestore, T document) =>
      firestore.collection(path).cvAdd(document);

  /// Add a map
  Future<CvDocumentReference<T>> addMap(Firestore firestore, Model data) async {
    var rawRef = await raw(firestore).add(data);
    return CvDocumentReference<T>(rawRef.path);
  }

  /// Raw document reference
  CollectionReference raw(Firestore firestore) => firestore.collection(path);

  /// Cast to a different type
  CvCollectionReference<TT> cast<TT extends CvFirestoreDocument>() =>
      CvCollectionReference<TT>(path);

  /// New path, same type to a different type
  CvCollectionReference<T> withPath(String path) =>
      CvCollectionReference<T>(path);

  /// New path, same type to a different type
  CvCollectionReference<T> withId(String id) =>
      CvCollectionReference<T>(firestorePathReplaceId(path, id));
  @override
  String toString() => 'CvCollectionReference<$T>($path)';
}

/// Collection reference helpers.
extension CollectionReferenceCvExtension on CollectionReference {
  /// Convert from raw reference.
  CvCollectionReference<T> cv<T extends CvFirestoreDocument>() =>
      CvCollectionReference<T>(path);
}

/// Collection reference helpers.
extension CvCollectionReferenceExtension<T extends CvFirestoreDocument>
    on CvCollectionReference<T> {
  /// Get a list of document
  Future<List<T>> get(Firestore firestore) =>
      firestore.collection(path).cvGet();

  /// Get a list of document
  Stream<List<T>> onSnapshots(Firestore firestore) =>
      firestore.collection(path).cvOnSnapshots();

  /// Document changed
  Stream<List<T>> onSnapshotsSupport(Firestore firestore,
          {TrackChangesPullOptions? options}) =>
      firestore.collection(path).cvOnSnapshotsSupport(options: options);
}
