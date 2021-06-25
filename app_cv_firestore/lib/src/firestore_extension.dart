import 'dart:async';

import 'package:tekartik_app_cv/app_cv.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

void _ensurePathSet(CvFirestoreDocument document) {
  if (!document.hasId) {
    throw ArgumentError('path must be set on document $document');
  }
}

/// Easy extension
extension CvFirestoreExt on Firestore {
  /// Add a document
  Future<void> cvSet<T extends CvFirestoreDocument>(T document,
      [SetOptions? options]) async {
    _ensurePathSet(document);
    await doc(document.path).set(document.toModel(), options);
  }

  /// Update a document
  Future<void> cvUpdate<T extends CvFirestoreDocument>(T document) async {
    _ensurePathSet(document);
    await doc(document.path).update(document.toModel());
  }

  /// Add a document to collection, [document.path] is ignored.
  Future<T> cvAdd<T extends CvFirestoreDocument>(
      String path, T document) async {
    return await collection(path).cvAdd(document);
  }

  /// Add a document
  Future<T> cvGet<T extends CvFirestoreDocument>(String path) async {
    return (await doc(path).get()).cv();
  }

  /// Transaction
  Future<T> cvRunTransaction<T>(
      FutureOr<T> Function(CvFirestoreTransaction transaction) action) {
    return runTransaction<T>((transaction) async {
      return action(CvFirestoreTransaction(this, transaction));
    });
  }

  /// Batch
  CvFirestoreWriteBatch cvBatch() {
    return CvFirestoreWriteBatch(this, batch());
  }
}

/// Transaction
class CvFirestoreTransaction extends Transaction {
  final Firestore _firestore;
  final Transaction _transaction;

  CvFirestoreTransaction(this._firestore, this._transaction);

  /// Delete
  void cvDelete(String path) {
    delete(_firestore.doc(path));
  }

  /// Returns non-null [Future] of the read data in a [DocumentSnapshot].
  Future<T> cvGet<T extends CvFirestoreDocument>(String path) async {
    return (await get(_firestore.doc(path))).cv();
  }

  /// Returns non-null [Future] of the read data in a [DocumentSnapshot].
  Future<T> refGet<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref) async {
    return await cvGet<T>(ref.path);
  }

  /// Returns non-null [Future] of the read data in a [DocumentSnapshot].
  void refDelete<T extends CvFirestoreDocument>(CvDocumentReference<T> ref) =>
      cvDelete(ref.path);

  /// Set
  void cvSet<T extends CvFirestoreDocument>(T document, [SetOptions? options]) {
    _ensurePathSet(document);
    set(_firestore.doc(document.path), document.toModel(), options);
  }

  /// update
  void cvUpdate<T extends CvFirestoreDocument>(T document) {
    _ensurePathSet(document);
    update(_firestore.doc(document.path), document.toModel());
  }

  @override
  void delete(DocumentReference documentRef) {
    _transaction.delete(documentRef);
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) {
    return _transaction.get(documentRef);
  }

  @override
  void set(DocumentReference documentRef, Map<String, Object?> data,
      [SetOptions? options]) {
    _transaction.set(documentRef, data, options);
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    _transaction.update(documentRef, data);
  }
}

/// Easy extension
extension CvFirestoreCollectionReferenceExt on CollectionReference {
  /// [document.path] is ignored and update in the response
  Future<T> cvAdd<T extends CvFirestoreDocument>(T document) async {
    document.path = (await add(document.toModel())).path;
    return document;
  }
}

/// Easy extension
extension CvFirestoreQueryExt on Query {
  /// path is updated upon add
  Future<List<T>> cvGet<T extends CvFirestoreDocument>() async {
    var querySnapshot = await get();
    return querySnapshot.cv<T>();
  }

  Stream<List<T>> cvOnSnapshots<T extends CvFirestoreDocument>() => onSnapshot()
          .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.docs.cv<T>());
      }));
}

/// Easy extension
extension CvFirestoreDocumentSnapshotExt on DocumentSnapshot {
  /// Create a DbRecord from a snapshot
  T cv<T extends CvFirestoreDocument>() {
    var path = ref.path;

    if (!exists) {
      return cvBuildModel<T>({})
        ..path = path
        // ignore: invalid_use_of_visible_for_testing_member
        ..exists = false;
    } else {
      var data = this.data;
      return (cvBuildModel<T>(data)..path = path)
        ..fromModel(data)
        // ignore: invalid_use_of_visible_for_testing_member
        ..exists = exists;
    }
  }
}

/// Easy extension
extension CvFirestoreDocumentReferenceExt on DocumentReference {
  /// Get a document
  Future<T> cvGet<T extends CvFirestoreDocument>() async {
    return (await get()).cv();
  }

  /// on snapshots
  Stream<T> cvOnSnapshot<T extends CvFirestoreDocument>() => onSnapshot()
          .transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
        sink.add(data.cv<T>());
      }));
}

/// Easy extension
extension CvFirestoreDocumentSnapshotsExt on Iterable<DocumentSnapshot> {
  /// Create a list of DbRecords from a snapshot
  List<T> cv<T extends CvFirestoreDocument>() =>
      lazy<T>((snapshot) => snapshot.cv());
}

/// Easy extension
extension CvFirestoreQuerySnapshotExt on QuerySnapshot {
  /// Create a list of DbRecords from a snapshot
  List<T> cv<T extends CvFirestoreDocument>() => docs.cv<T>();
}

/// Easy extension
class CvFirestoreWriteBatch extends WriteBatch {
  final Firestore _firestore;
  final WriteBatch _writeBatch;

  CvFirestoreWriteBatch(this._firestore, this._writeBatch);

  @override
  Future commit() => _writeBatch.commit();

  @override
  void set(DocumentReference ref, Map<String, Object?> data,
          [SetOptions? options]) =>
      _writeBatch.set(ref, data, options);

  @override
  void update(DocumentReference ref, Map<String, Object?> data) =>
      _writeBatch.update(ref, data);

  @override
  void delete(DocumentReference ref) => _writeBatch.delete(ref);

  /// set document
  void cvSet(CvFirestoreDocument document, [SetOptions? options]) {
    _ensurePathSet(document);
    set(_firestore.doc(document.path), document.toModel(), options);
  }

  void cvUpdate(CvFirestoreDocument document) {
    _ensurePathSet(document);
    update(_firestore.doc(document.path), document.toModel());
  }

  void cvDelete(String path) => delete(_firestore.doc(path));
}
