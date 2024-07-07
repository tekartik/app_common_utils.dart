/*
extension

@visibleForTesting
set exists(bool exists);*/

import 'package:cv/src/content_values.dart'; // ignore: implementation_imports
import 'package:path/path.dart';
import 'package:tekartik_app_cv_firestore/app_cv_firestore.dart';

mixin _WithPath implements CvFirestoreDocument {
  String? _path;

  /// Id
  @override
  String get id => url.basename(path);

  /// Set the path
  @override
  String get path => _path!;

  /// Get the path
  @override
  set path(String path) => _path = path;

  /// A document without id/path can only be added to a collection
  @override
  bool get hasId => _path != null;

  /// Can only be called on read documents
  @override
  bool get exists => _exists ?? false;

  bool? _exists;

  @override
  String toString() => '${hasId ? path : '(new)'} ${super.toString()}';
}

/// common helper
extension CvFirestoreDocumentExt<T extends CvFirestoreDocument> on T {
// extension CvFirestoreDocumentExt on CvFirestoreDocument {
  /// Id or null
  String? get idOrNull => hasId ? id : null;

  /// Path or null
  String? get pathOrNull => hasId ? path : null;

  /// Reference
  CvDocumentReference<T>? get refOrNull => hasId ? ref : null;

  /// Reference
  CvDocumentReference<T> get ref => CvDocumentReference<T>(path);
}

/// common helper
extension CvFirestoreDocumentPrvExt on CvFirestoreDocument {
  set prvExists(bool exists) {
    (this as _WithPath)._exists = exists;
  }
}

/// Only the content is compared on equals
abstract class CvFirestoreDocumentBase extends CvModelBase with _WithPath {}

/// Only the content is compared on equals
abstract class CvFirestoreDocument implements CvModel {
  /// Id
  String get id;

  /// Path
  String get path;

  /// Set the path for later use
  set path(String path);

  /// True if it has an id (false for new document before being added)
  bool get hasId;

  /// True if the document exists (after read) or false for new document before being added)

  bool get exists;
}

/// Modifiable map.
abstract class CvFirestoreMapDocument implements CvFirestoreDocument {
  /// Basic content values factory
  factory CvFirestoreMapDocument() => _FsDocumentMap();

  /// Predefined fields, values can be changed but none can added.
  /// Usage discouraged unless you known the limitations.
  factory CvFirestoreMapDocument.withFields(List<CvField> list) {
    return _FsDocumentWithCvFields(list);
  }
}

/// Only the content is compared on equals
class _FsDocumentMap extends ContentValuesMap
    with _WithPath
    implements CvFirestoreMapDocument {}

/*
/// Easy extension
extension CvFsDocumentExt on CvFsDocument {
  Future<void> add(Firestore)
}


 */
class _FsDocumentWithCvFields extends CvBase
    with _WithPath
    implements CvFirestoreMapDocument {
  @override
  final List<CvField> fields;

  _FsDocumentWithCvFields(this.fields);
}
