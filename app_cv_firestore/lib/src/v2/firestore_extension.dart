import 'package:tekartik_app_cv_firestore/app_cv_firestore_v2.dart';
import 'package:tekartik_app_cv_firestore/src/v2/cv_document.dart'
    show CvFirestoreDocumentPrvExt;
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/foundation/constants.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';

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
    await doc(document.path).set(document.toMap(), options);
  }

  /// Update a document
  Future<void> cvUpdate<T extends CvFirestoreDocument>(T document) =>
      docUpdate(document);

  /// Update a document
  Future<void> docUpdate<T extends CvFirestoreDocument>(T document) async {
    _ensurePathSet(document);
    await doc(document.path).update(document.toMap());
  }

  /// Update a document
  Future<void> docDelete<T extends CvFirestoreDocument>(T document) async {
    _ensurePathSet(document);
    await pathDelete(document.path);
  }

  /// Add a document to collection, [document.path] is ignored.
  Future<T> cvAdd<T extends CvFirestoreDocument>(
      String path, T document) async {
    return await collection(path).cvAdd(document);
  }

  /// Returns non-null [Future] of the read data in a [DocumentSnapshot].
  Future<void> refDelete<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref) async {
    await pathDelete(ref.path);
  }

  /// Returns non-null [Future] of the read data in a [DocumentSnapshot].
  Future<T> refGet<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref) async {
    return await cvGet<T>(ref.path);
  }

  /// Set
  Future<void> refSet<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, T document,
      [SetOptions? options]) async {
    await doc(ref.path).set(document.toMap(), options);
  }

  /// Delete
  Future<void> pathDelete(String path) async {
    await doc(path).delete();
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
  /// TODO bad naming
  @Deprecated('use path delete')
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

  /// Set
  void refSet<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, T document,
      [SetOptions? options]) async {
    refSetMap(ref, document.toMap(), options);
  }

  /// Set
  void refSetMap<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, Model map,
      [SetOptions? options]) async {
    set(_firestore.doc(ref.path), map, options);
  }

  /// Returns non-null [Future] of the read data in a [DocumentSnapshot].
  void refDelete<T extends CvFirestoreDocument>(CvDocumentReference<T> ref) =>
      pathDelete(ref.path);

  /// Update
  void refUpdate<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, T document) async {
    refUpdateMap(ref, document.toMap());
  }

  /// Update
  void refUpdateMap<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, Model map) async {
    update(ref.raw(_firestore), map);
  }

  /// Set
  void cvSet<T extends CvFirestoreDocument>(T document, [SetOptions? options]) {
    _ensurePathSet(document);
    set(_firestore.doc(document.path), document.toMap(), options);
  }

  /// update
  void cvUpdate<T extends CvFirestoreDocument>(T document) {
    _ensurePathSet(document);
    refUpdate(document.ref, document);
  }

  @override
  void delete(DocumentReference documentRef) {
    _transaction.delete(documentRef);
  }

  void pathDelete(String path) {
    _transaction.delete(_firestore.doc(path));
  }

  /// Doc deletion
  void docDelete<T extends CvFirestoreDocument>(T document) {
    pathDelete(document.path);
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
    document.path = (await add(document.toMap())).path;
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
extension CvFirestoreDocumentIterableExt<T extends CvFirestoreDocument>
    on Iterable<T> {
  /// List to map
  Map<String, T> toMap() => {for (var item in this) item.id: item};
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
        ..prvExists = false;
    } else {
      var data = this.data;
      return (cvBuildModel<T>(data)..path = path)
        ..fromMap(data)
        // ignore: invalid_use_of_visible_for_testing_member
        ..prvExists = exists;
    }
  }

  T cvType<T extends CvFirestoreDocument>(Type type) {
    var path = ref.path;

    if (!exists) {
      return cvTypeBuildModel<T>(type, {})
        ..path = path
        // ignore: invalid_use_of_visible_for_testing_member
        ..prvExists = false;
    } else {
      var data = this.data;
      return (cvTypeBuildModel<T>(type, data)..path = path)
        ..fromMap(data)
        // ignore: invalid_use_of_visible_for_testing_member
        ..prvExists = exists;
    }
  }
}

/// Easy extension
extension CvFirestoreDocumentReferenceExt on DocumentReference {
  /// Get a document
  Future<T> cvGet<T extends CvFirestoreDocument>() async {
    return (await get()).cv();
  }

  StreamTransformer<DocumentSnapshot, T>
      _snapshotTransformer<T extends CvFirestoreDocument>() =>
          StreamTransformer<DocumentSnapshot, T>.fromHandlers(
              handleData: (data, sink) {
            try {
              var converted = data.cv<T>();
              sink.add(converted);
              // devPrint('cvOnSnapshot $converted');
            } catch (e) {
              if (kDebugMode) {
                print('cvOnSnapshot.error: $e');
              }
              rethrow;
            }
          });

  /// on snapshots
  Stream<T> cvOnSnapshot<T extends CvFirestoreDocument>() =>
      onSnapshot().transform(_snapshotTransformer<T>());

  /// on snapshots
  Stream<T> cvOnSnapshotSupport<T extends CvFirestoreDocument>(
          {TrackChangesPullOptions? options}) =>
      onSnapshotSupport(options: options).transform(_snapshotTransformer<T>());
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

  /// set document
  void cvSet(CvFirestoreDocument document, [SetOptions? options]) {
    _ensurePathSet(document);
    set(_firestore.doc(document.path), document.toMap(), options);
  }

  void refSet<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, T document,
      [SetOptions? options]) {
    refSetMap<T>(ref, document.toMap(), options);
  }

  /// Set
  void refSetMap<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, Model map,
      [SetOptions? options]) async {
    set(ref.raw(_firestore), map, options);
  }

  @override
  void update(DocumentReference ref, Map<String, Object?> data) =>
      _writeBatch.update(ref, data);

  void cvUpdate<T extends CvFirestoreDocument>(T document) {
    _ensurePathSet(document);
    update(_firestore.doc(document.path), document.toMap());
  }

  void refUpdate<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, T document) {
    refUpdateMap(ref, document.toMap());
  }

  void refUpdateMap<T extends CvFirestoreDocument>(
      CvDocumentReference<T> ref, Model map) {
    update(ref.raw(_firestore), map);
  }

  @override
  void delete(DocumentReference ref) => _writeBatch.delete(ref);

  void refDelete<T extends CvFirestoreDocument>(CvDocumentReference<T> ref) =>
      delete(ref.raw(_firestore));

  // ? now
  // @Deprecated('use refDelete')
  void cvDelete(String path) => delete(_firestore.doc(path));
}
