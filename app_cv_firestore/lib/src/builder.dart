import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:tekartik_app_cv/app_cv.dart';
import 'package:tekartik_app_cv/src/content_values.dart';

/// Add builder
void cvFirestoreAddBuilder<T extends CvModel>(
    T Function(Map contextData) builder) {
  cvAddBuilder(builder);
}

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
  late bool exists;

  @override
  String toString() => '${hasId ? path : '(new)'} ${super.toString()}';
}

/// Only the content is compared on equals
abstract class CvFirestoreDocument implements CvModel {
  /// Id
  String get id;

  /// Path
  String get path;

  set path(String path);

  bool get hasId;

  bool get exists;

  @visibleForTesting
  set exists(bool exists);
}

/// common helper
extension CvFirestoreDocumentExt on CvFirestoreDocument {
  /// Id or null
  String? get idOrNull => hasId ? id : null;

  /// Path or null
  String? get pathOrNull => hasId ? path : null;
}

/// Only the content is compared on equals
abstract class CvFirestoreDocumentBase extends CvModelBase with _WithPath {}

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
