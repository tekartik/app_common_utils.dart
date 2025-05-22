import 'package:cv/cv.dart';
import 'package:idb_shim/sdb.dart';
import 'scv_record_ref.dart';
import 'scv_store_ref.dart';
import 'scv_types.dart';

/// Record with a key (int or String).
abstract class ScvRecord<K extends ScvKey> implements CvModel {
  SdbRecordRef<K, Model>? _ref;
}

/// Record with a string key
typedef ScvStringRecord = ScvRecord<String>;

/// Record with an int key
typedef ScvIntRecord = ScvRecord<int>;

/// Base record implementation. Protected fields:
/// - ref
abstract class ScvRecordBase<K extends ScvKey> extends CvModelBase
    implements ScvRecord<K> {
  @override
  SdbRecordRef<K, Model>? _ref;
}

/// Record with a string key
abstract class ScvStringRecordBase extends ScvRecordBase<String>
    implements ScvStringRecord {}

/// Record with an int key
abstract class ScvIntRecordBase extends ScvRecordBase<int>
    implements ScvIntRecord {}

/// Access to ref.
extension ScvRecordToRefExt<K extends ScvKey> on ScvRecord<K> {
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

/// Easy extension
extension ScvRecordListExt<K extends ScvKey, V> on List<ScvRecord<K>> {
  /// List of ifs
  List<K> get ids => map((record) => record.id).toList();
}
