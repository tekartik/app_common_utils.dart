import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/query_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/firestore_common.dart'; // ignore: implementation_imports

class QueryImpl with QueryMixin, FirestoreQueryExecutorMixin {
  @override
  QueryMixin clone() => QueryImpl()..queryInfo = queryInfo.clone();

  @override
  Future<QuerySnapshot> get() {
    throw UnimplementedError();
  }

  @override
  Stream<QuerySnapshot> onSnapshot() {
    throw UnimplementedError();
  }
}

/// Query reference strong type helper
class CvQueryReference<T extends CvFirestoreDocument> {
  ///
  final Query _impl;
  final CvCollectionReference<T> _collectionReference;

  QueryInfo get _queryInfo => (_impl as QueryImpl).queryInfo;

  /// New query reference
  @internal
  CvQueryReference(this._collectionReference)
      : _impl = QueryImpl()..queryInfo = QueryInfo();

  CvQueryReference._(this._collectionReference, Query impl) : _impl = impl;

  Future<List<T>> get(Firestore firestore) async {
    var query =
        await applyQueryInfo(firestore, _collectionReference.path, _queryInfo);
    return query.cvGet<T>();
  }

  @Deprecated('User onSnapshots instead')
  Stream<List<T>> onSnapshot(Firestore firestore) => onSnapshot(firestore);

  /// query snapshots
  Stream<List<T>> onSnapshots(Firestore firestore) {
    final lock = Lock();
    StreamSubscription? streamSubscription;
    var done = false;
    late StreamController<List<T>> ctlr;
    ctlr = StreamController<List<T>>(onListen: () {
      lock.synchronized(() async {
        var query = await applyQueryInfo(
            firestore, _collectionReference.path, _queryInfo);
        streamSubscription = query.cvOnSnapshots<T>().listen((event) {
          if (!done) {
            ctlr.add(event);
          }
        });
      });
    }, onCancel: () {
      done = true;
      lock.synchronized(() {
        streamSubscription?.cancel();
      });
    });
    return ctlr.stream;
  }

  CvQueryReference<T> limit(int limit) =>
      CvQueryReference._(_collectionReference, _impl.limit(limit));

  CvQueryReference<T> orderBy(String key, {bool? descending}) =>
      CvQueryReference._(
          _collectionReference, _impl.orderBy(key, descending: descending));

  CvQueryReference<T> select(List<String> keyPaths) =>
      CvQueryReference._(_collectionReference, _impl.select(keyPaths));

  // CvQueryReference<T>  offset(int offset);

  CvQueryReference<T> startAt(
          {DocumentSnapshot? snapshot, List<Object?>? values}) =>
      CvQueryReference._(_collectionReference,
          _impl.startAt(snapshot: snapshot, values: values));

  CvQueryReference<T> startAfter(
          {DocumentSnapshot? snapshot, List<Object?>? values}) =>
      CvQueryReference._(_collectionReference,
          _impl.startAfter(snapshot: snapshot, values: values));

  CvQueryReference<T> endAt(
          {DocumentSnapshot? snapshot, List<Object?>? values}) =>
      CvQueryReference._(_collectionReference,
          _impl.endAt(snapshot: snapshot, values: values));

  CvQueryReference<T> endBefore(
          {DocumentSnapshot? snapshot, List<Object?>? values}) =>
      CvQueryReference._(_collectionReference,
          _impl.endBefore(snapshot: snapshot, values: values));

  CvQueryReference<T> where(
    String fieldPath, {
    dynamic isEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<Object>? arrayContainsAny,
    List<Object>? whereIn,
    bool? isNull,
  }) =>
      CvQueryReference._(
          _collectionReference,
          _impl.where(
            fieldPath,
            isLessThanOrEqualTo: isLessThanOrEqualTo,
            isNull: isNull,
            isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
            isLessThan: isLessThan,
            arrayContains: arrayContains,
            arrayContainsAny: arrayContainsAny,
            whereIn: whereIn,
            isGreaterThan: isGreaterThan,
            isEqualTo: isEqualTo,
          ));

  /// Raw query reference, async since it might require a read first
  Future<Query> rawASync(Firestore firestore) async =>
      await applyQueryInfo(firestore, _collectionReference.path, _queryInfo);
}
