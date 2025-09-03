import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query.dart';

/// Helpers to delete query results
extension CvFirestoreQueryReferenceUtilsExt<T extends CvFirestoreDocument>
    on CvQueryReference<T> {
  Future<int> delete(
    Firestore firestore, {

    /// Needed as query limit is ignored otherwise
    int? limit,
    int? batchSize,
    Iterable<String>? keepIds,
  }) async {
    return (await rawASync(
      firestore,
    )).queryDelete(batchSize: batchSize, keepIds: keepIds, limit: limit);
  }
}
