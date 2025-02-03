import 'package:sembast/sembast.dart';

import 'db_record.dart';

/// Query ref
class CvQueryRef<K, V extends DbRecord<K>> {
  /// Raw ref
  final QueryRef<K, Map<String, Object?>> rawRef;

  /// Constructor
  CvQueryRef(this.rawRef);
}

/// Common helpers
extension CvQueryRefExt<K, V extends DbRecord<K>> on CvQueryRef<K, V> {
  /// Get a single record
  Future<V?> getRecord(DatabaseClient db) async {
    return (await rawRef.getSnapshot(db))?.cv();
  }

  /// Get a single record
  V? getRecordSync(DatabaseClient db) {
    return rawRef.getSnapshotSync(db)?.cv();
  }

  /// Get all records
  Future<List<V>> getRecords(DatabaseClient db) async {
    return (await rawRef.getSnapshots(db)).cv();
  }

  /// Get all records
  List<V> getRecordsSync(DatabaseClient db) {
    return rawRef.getSnapshotsSync(db).cv();
  }

  /// Track changes
  Stream<V?> onRecord(Database db) =>
      rawRef.onSnapshot(db).map((snapshot) => snapshot?.cv<V>());

  /// Track changes
  Stream<List<V>> onRecords(Database db) =>
      rawRef.onSnapshots(db).map((snapshots) => snapshots.cv<V>());

  /// Track changes, first event is emitted synchronously
  Stream<V?> onRecordSync(Database db) =>
      rawRef.onSnapshotSync(db).map((snapshot) => snapshot?.cv<V>());

  /// Track changes, first event is emitted synchronously
  Stream<List<V>> onRecordsSync(Database db) =>
      rawRef.onSnapshotsSync(db).map((snapshots) => snapshots.cv<V>());

  /// Count
  Future<int> count(DatabaseClient db) => rawRef.count(db);

  /// Count sync
  int countSync(DatabaseClient db) => rawRef.countSync(db);

  /// onCount
  Stream<int> onCount(Database db) => rawRef.onCount(db);

  /// onCountSync
  Stream<int> onCountSync(Database db) => rawRef.onCountSync(db);

  /// Delete
  Future<int> delete(DatabaseClient db) => rawRef.delete(db);

  /// Get keys
  Future<List<K>> getKeys(DatabaseClient db) async {
    return (await rawRef.getKeys(db));
  }

  /// Get keys
  List<K> getKeysSync(DatabaseClient db) {
    return (rawRef.getKeysSync(db));
  }

  /// onKeys
  Stream<List<K>> onKeys(Database db) => rawRef.onKeys(db);

  /// onKeysSync
  Stream<List<K>> onKeysSync(Database db) => rawRef.onKeysSync(db);
}
