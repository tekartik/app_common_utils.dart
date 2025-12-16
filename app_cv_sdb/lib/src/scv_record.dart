import 'package:cv/cv.dart';
import 'package:idb_shim/sdb.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'scv_record_ref.dart';
import 'scv_store_ref.dart';

/// Record with a key (int or String).
abstract class ScvRecord<K extends SdbKey> implements CvModel {
  SdbRecordRef<K, Model>? _ref;
}

/// Record with a string key
typedef ScvStringRecord = ScvRecord<String>;

/// Record with an int key
typedef ScvIntRecord = ScvRecord<int>;

/// Base record implementation. Protected fields:
/// - ref
abstract class ScvRecordBase<K extends SdbKey> extends CvModelBase
    implements ScvRecord<K> {
  @override
  SdbRecordRef<K, Model>? _ref;

  @override
  String toString() => _ref == null
      ? '<null> ${super.toString()}'
      : '$rawRef ${super.toString()}';
}

/// Record with a string key
abstract class ScvStringRecordBase extends ScvRecordBase<String>
    implements ScvStringRecord {}

/// Record with an int key
abstract class ScvIntRecordBase extends ScvRecordBase<int>
    implements ScvIntRecord {}

/// Access to ref.
extension ScvRecordToRefExt<K extends SdbKey> on ScvRecord<K> {
  /// Get the record ref
  ScvRecordRef<K, ScvRecord<K>> get ref =>
      ScvStoreRef<K, ScvRecord<K>>(rawRef.store.name).record(rawRef.key);

  /// Get the record ref
  ScvRecordRef<K, ScvRecord<K>>? get refOrNull => hasId ? ref : null;

  /// Set the record ref
  set ref(ScvRecordRef<K, ScvRecord<K>> ref) => rawRef = ref.rawRef;

  /// Set the record ref
  set refOrNull(ScvRecordRef<K, ScvRecord<K>>? ref) =>
      ref == null ? _ref = null : this.ref = ref;

  /// Get the raw record ref
  SdbRecordRef<K, Model> get rawRef => _ref!;

  /// set the raw record ref
  ///@deprecated
  set rawRef(SdbRecordRef<K, Model> ref) => _ref = ref;

  /// Check hasId first
  K get id => rawRef.key;

  /// Id or null
  K? get idOrNull => _ref?.key;

  set idOrNull(K? id) {
    if (id == null) {
      _ref = null;
    } else {
      this.id = id;
    }
  }

  /// Only true f newly created record
  bool get hasId => _ref != null;

  /// Change the id
  set id(K id) => rawRef = rawRef.store.record(id);
}

/// Public extension on DbRecord
extension ScvRecordExt<T extends ScvRecord> on T {
  /// Copy content and ref if not null
  T scvClone() {
    var newRecord = clone();
    if (hasId) {
      newRecord.rawRef = rawRef;
    }
    return newRecord;
  }
}

/// Private extension on DbRecord
extension ScvRecordExtInternal<T extends ScvRecord> on T {
  /// Copy content and ref if not null
  Model toDbMap() {
    return toMap();
  }

  /// return a list if keyPath is an array
  ///
  /// if [keyPath] is a, the list cannot contain null values and null is returned instead.
  Object? getKeyValue(Object? keyPath) {
    if (keyPath is String) {
      return getFieldValue(keyPath);
    } else if (keyPath is List) {
      final keyList = keyPath;
      var keys = List<Object?>.generate(
        keyList.length,
        (i) => getFieldValue(keyPath[i] as String),
      );
      if (keys.where((element) => element == null).isNotEmpty) {
        /// the list cannot contain null values
        return null;
      }
      return keys;
    }
    throw 'keyPath $keyPath not supported';
  }

  /// return a list if keyPath is an array
  ///
  /// if [keyPath] is a, the list cannot contain null values and null is returned instead.
  void setKeyValue(Object? keyPath, Object value) {
    if (keyPath is SdbKeyPath) {
      if (keyPath.isSingle) {
        keyPath = keyPath.keyPaths.first;
      } else {
        keyPath = keyPath.keyPaths;
      }
    }
    if (keyPath is String) {
      return setFieldValue(keyPath, value);
    } else if (keyPath is List) {
      final keyList = keyPath;
      if (isDebug) {
        if (value is! List) {
          throw ArgumentError.value(value, 'key value', 'is not a list');
        }
        if (keyPath is! List<String>) {
          throw ArgumentError.value(
            keyPath,
            'keyPath',
            'is not a list of string',
          );
        }
        if (value.length != keyList.length) {
          throw ArgumentError.value(
            '$keyPath: $value',
            'keyPath: value',
            'length do not match (${keyList.length} vs ${value.length}',
          );
        }
      }

      /// value must be a list

      final valueList = value as List<Object?>;
      assert(keyList.length == valueList.length);
      for (var i = 0; i < keyList.length; i++) {
        setFieldValue(keyList[i] as String, valueList[i]!);
      }
    } else {
      throw 'keyPath $keyPath not supported';
    }
  }

  /// Split a filed by its dot (.) to get a part
  List<String> getFieldParts(String field) => field.split('.');

  /// Get map field helper.
  F? getFieldValue<F extends Object>(String field) {
    var cvField = fieldAtPath<F>(getFieldParts(field));
    return cvField?.value;
  }

  /// Set a field value.
  void setFieldValue<F extends Object>(String field, F? value) {
    var cvField = fieldAtPath<F>(getFieldParts(field));
    cvField?.value = value;
  }
}

/// Easy extension
extension ScvRecordListExt<K extends SdbKey, V> on List<ScvRecord<K>> {
  /// List of ifs
  List<K> get ids => map((record) => record.id).toList();
}

/// Easy extension
extension ScvRecordSnapshotExt<K extends SdbKey>
    on SdbRecordSnapshot<K, Model> {
  /// Create a DbRecord from a snapshot
  T cv<T extends ScvRecord<K>>() {
    return (cvBuildModel<T>(value)..rawRef = this)..fromMap(value);
  }
}

/// Easy extension
extension ScvRecordSnapshotListExt<K extends SdbKey>
    on List<SdbRecordSnapshot<K, Model>> {
  /// Create a DbRecord from a snapshot
  List<T> cv<T extends ScvRecord<K>>() =>
      lazy<T>((snapshot) => snapshot.cv<T>()).toList();
}
