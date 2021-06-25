import 'package:path/path.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_app_cv_firestore/src/cv_document_reference.dart';
import 'package:tekartik_app_cv_firestore/src/cv_query_reference.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Collection helper
class CvCollectionReference<T extends CvFirestoreDocument> {
  final String path;

  CvCollectionReference(this.path);

  /// Get a list of document
  Future<List<T>> get(Firestore firestore) =>
      firestore.collection(path).cvGet();

  /// Get a list of document
  Stream<List<T>> onSnapshots(Firestore firestore) =>
      firestore.collection(path).cvOnSnapshots();

  /// Document reference
  CvDocumentReference<T> doc(String path) =>
      CvDocumentReference<T>(url.join(this.path, path));

  /// Create a query
  CvQueryReference<T> query() => CvQueryReference(this);
}
