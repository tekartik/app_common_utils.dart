import 'dart:async';

import 'package:cv/cv.dart';
import 'package:sembast/sembast.dart';
import 'package:synchronized/synchronized.dart';

/// A pointer to an Index definition
abstract class IndexRef<K, PK> {
  /// The key path
  String get path;

  /// Store reference
  StoreRef<PK, Model> get store;
}

/// IndexRef helpers
extension SembastIndexRefHelperExtension<K, PK> on IndexRef<K, PK> {
  /// Get the key from a snapshot.
  K? key(RecordSnapshot<PK, Model> snapshot) => snapshot.value[path] as K?;
}

/// Create the index
extension SembastStoreIndexExtension<PK> on StoreRef<PK, Model> {
  IndexRef<K, PK> index<K>(String path) {
    return _SembastIndexRef(store: this, path: path);
  }
}

/// The implementation.
class _SembastIndexRef<K, PK> implements IndexRef<K, PK> {
  _SembastIndexRef({required this.store, required this.path});

  @override
  final StoreRef<PK, Model> store;

  @override
  String path;
}

/// Database helper for indecies
extension SembastDatabaseIndexExtension on Database {
  /// Create and maintain the index on a database.
  ///
  /// If [throwOnConflict] is true, a StateError is thrown in case of duplicates.
  ///
  /// Otherwise you must read and write in a transaction to avoid duplicates
  DatabaseIndex<K, PK> index<K, PK>(
    IndexRef<K, PK> indexRef, {
    bool throwOnConflict = false,
  }) {
    return _SembastDatabaseUniqueIndex(
      this,
      indexRef,
      throwOnConflict: throwOnConflict,
    );
  }
}

/// The database index to create right after opening the database
abstract class DatabaseIndex<K, PK> {
  /// Get an index record object to access/manipulate the record.
  DatabaseClientIndexRecord<K, PK> record(K key);

  /// Get an index record object to access/maninpulate the record in transaction.
  DatabaseClientIndexRecord<K, PK> transactionRecord(
    Transaction transaction,
    K key,
  );

  void dispose();
}

/// IndexRef helpers
extension SembastDatabaseIndexHelperExtension<K, PK> on DatabaseIndex<K, PK> {
  /// Get the key from a snapshot.
  K? key(RecordSnapshot<PK, Model> snapshot) =>
      (this as _SembastDatabaseUniqueIndex<K, PK>).indexRef.key(snapshot);
}

/// Index record reference.
abstract class DatabaseClientIndexRecord<K, PK> {
  DatabaseIndex<K, PK> get index;
  K get key;

  /// Get a record snapshot from the database.
  Future<RecordSnapshot<PK, Model>?> getSnapshot();

  /// Return true if the record exists.
  Future<bool> exists();

  /// Create the record if it does not exist.
  ///
  /// A new record gets the index field set to [key].
  ///
  /// Returns the key if inserted, null otherwise.
  Future<PK?> add(Model value);

  /// Save a record, create if needed.
  ///
  /// if [merge] is true and the field exists, data is merged
  ///
  /// The saved value holds the index field set to [key], unless [value] sets
  /// it (an existing record then moves to that index key).
  ///
  /// Returns the updated value.
  Future<Model> put(Model value, {bool? merge});

  /// Update a record.
  ///
  /// If it does not exist, return null. if value is a map, keys with dot values
  /// refer to a path in the map, unless the key is specifically escaped
  ///
  /// Returns the updated value.
  Future<Model?> update(Model value);

  /// Delete the record.
  Future delete();
}

class _SembastDatabaseIndexRecord<K, PK>
    implements DatabaseClientIndexRecord<K, PK> {
  final DatabaseClient client;
  @override
  final DatabaseIndex<K, PK> index;

  _SembastDatabaseUniqueIndex<K, PK> get _index =>
      index as _SembastDatabaseUniqueIndex<K, PK>;

  @override
  final K key;

  _SembastDatabaseIndexRecord(this.index, this.key, this.client);

  @override
  Future<RecordSnapshot<PK, Model>?> getSnapshot() async {
    return _index._clientGetSnapshot(client, key);
  }

  /// Return true if the record exists.
  @override
  Future<bool> exists() => _index._clientExists(client, key);

  /// Create the record if it does not exist.
  ///
  /// Returns the key if inserted, null otherwise.
  @override
  Future<PK?> add(Model value) async => _index._clientAdd(client, key, value);

  /// Save a record, create if needed.
  ///
  /// if [merge] is true and the field exists, data is merged
  ///
  /// Returns the updated value.
  @override
  Future<Model> put(Model value, {bool? merge}) =>
      _index._clientPut(client, key, value, merge: merge);

  /// Update a record.
  ///
  /// If it does not exist, return null. if value is a map, keys with dot values
  /// refer to a path in the map, unless the key is specifically escaped
  ///
  /// Returns the updated value.
  @override
  Future<Model?> update(Model value) async =>
      (await _index._clientUpdate(client, key, value));

  /// Delete the record.
  @override
  Future delete() async => _index._clientDelete(client, key);
}

class _SembastDatabaseUniqueIndex<K, PK> implements DatabaseIndex<K, PK> {
  final indexLock = Lock();
  final Database database;
  StoreRef<PK, Model> get store => indexRef.store;
  final IndexRef<K, PK> indexRef;
  String get path => indexRef.path;
  final bool throwOnConflict;

  _SembastDatabaseUniqueIndex(
    this.database,
    this.indexRef, {
    this.throwOnConflict = false,
  }) {
    // Call ready right away to fill the index and so that it is
    // not called in a transaction
    // ignore: unnecessary_statements
    _ready;
  }

  /// Access to primary key by map
  final pkMap = <K, PK>{};

  @override
  DatabaseClientIndexRecord<K, PK> record(K key) =>
      _SembastDatabaseIndexRecord(this, key, database);
  @override
  DatabaseClientIndexRecord<K, PK> transactionRecord(
    Transaction transaction,
    K key,
  ) => _SembastDatabaseIndexRecord(this, key, transaction);
  Future<RecordRef<PK, Model>?> _storeRecord(K key) async {
    await _ready;
    var pk = pkMap[key];
    if (pk == null) {
      return null;
    }
    return store.record(pk);
  }

  void _throwConflict(RecordSnapshot snapshot) {
    throw StateError(
      'Index conflict for key $path = ${key(snapshot.cast())} for $snapshot',
    );
  }

  void _addNewKey(K? indexKey, PK pk, RecordSnapshot snapshot) {
    if (indexKey != null) {
      if (throwOnConflict) {
        var existingPk = pkMap[indexKey];
        if (existingPk != null && existingPk != pk) {
          _throwConflict(snapshot);
        }
      }
      pkMap[indexKey] = pk;
    }
  }

  void _removeKey(K? indexKey, PK pk) {
    if (indexKey != null) {
      var removedPk = pkMap.remove(indexKey);
      // if not ours, keep it
      if (removedPk != null && removedPk != pk) {
        pkMap[indexKey] = removedPk;
      }
    }
  }

  /// Throws on the first change creating a duplicate, before any change is
  /// applied: sembast rolls the write back, the map must stay as it is.
  void _checkConflicts(List<RecordChange<PK, Model>> changes) {
    // Index keys as they would be after the changes already checked.
    var removed = <K>{};
    var added = <K, PK>{};
    PK? currentPk(K indexKey) {
      if (added.containsKey(indexKey)) {
        return added[indexKey];
      }
      if (removed.contains(indexKey)) {
        return null;
      }
      return pkMap[indexKey];
    }

    void remove(K? indexKey, PK pk) {
      if (indexKey != null && currentPk(indexKey) == pk) {
        added.remove(indexKey);
        removed.add(indexKey);
      }
    }

    void add(K? indexKey, PK pk, RecordSnapshot snapshot) {
      if (indexKey != null) {
        var existingPk = currentPk(indexKey);
        if (existingPk != null && existingPk != pk) {
          _throwConflict(snapshot);
        }
        added[indexKey] = pk;
      }
    }

    for (var change in changes) {
      var pk = change.ref.key;
      if (change.isDelete) {
        remove(key(change.oldSnapshot!), pk);
      } else if (change.isAdd) {
        add(key(change.newSnapshot!), pk, change.newSnapshot!);
      } else {
        var oldIndexKey = key(change.oldSnapshot!);
        var newIndexKey = key(change.newSnapshot!);
        if (oldIndexKey != newIndexKey) {
          remove(oldIndexKey, pk);
          add(newIndexKey, pk, change.newSnapshot!);
        }
      }
    }
  }

  FutureOr<void> _onChange(
    Transaction transaction,
    List<RecordChange<PK, Model>> changes,
  ) async {
    await indexLock.synchronized(() {
      if (throwOnConflict) {
        _checkConflicts(changes);
      }
      // Change in map
      for (var change in changes) {
        var pk = change.ref.key;

        if (change.isDelete) {
          var indexKey = key(change.oldSnapshot!);
          _removeKey(indexKey, pk);
        } else if (change.isAdd) {
          var indexKey = key(change.newSnapshot!);
          _addNewKey(indexKey, pk, change.newSnapshot!);
        } else {
          var oldIndexKey = key(change.oldSnapshot!);
          var newIndexKey = key(change.newSnapshot!);
          if (oldIndexKey != newIndexKey) {
            _removeKey(oldIndexKey, pk);
            _addNewKey(newIndexKey, pk, change.newSnapshot!);
          }
        }
      }
    });
  }

  /// Fill the index right away
  ///
  /// The first should never be called in a transaction. so the constructor
  /// should not be defined in a transaction
  late final Future<void> _ready = () {
    // Register for changes right away
    store.addOnChangesListener(database, _onChange);
    return indexLock.synchronized(() async {
      // Fill the index
      var snapshots = await store.find(database);
      for (var snapshot in snapshots) {
        var indexKey = key(snapshot);
        if (indexKey != null) {
          _addNewKey(indexKey, snapshot.key, snapshot);
        }
      }
    });
  }();

  // Get the snapshot
  Future<RecordSnapshot<PK, Model>?> _clientGetSnapshot(
    DatabaseClient client,
    K key,
  ) async {
    return (await _storeRecord(key))?.getSnapshot(client);
  }

  @override
  void dispose() {
    // Remove listener
    store.removeOnChangesListener(database, _onChange);
    pkMap.clear();
  }

  /// Return true if the record exists.
  Future<bool> _clientExists(DatabaseClient databaseClient, K key) async =>
      (await (await _storeRecord(key))?.exists(databaseClient)) ?? false;

  /// [value] with its index field set to [key].
  Model _indexedValue(K key, Model value) => {...value, path: key};

  /// Create the record if it does not exist.
  ///
  /// Returns the key if inserted, null otherwise.
  Future<PK?> _clientAdd(
    DatabaseClient databaseClient,
    K key,
    Model value,
  ) async {
    var record = await _storeRecord(key);
    if (record != null) {
      return await record.add(databaseClient, value);
    }
    // New index key, create the record.
    return await store.add(databaseClient, _indexedValue(key, value));
  }

  /// Save a record, create if needed.
  ///
  /// if [merge] is true and the field exists, data is merged
  ///
  /// Returns the updated value.
  Future<Model> _clientPut(
    DatabaseClient databaseClient,
    K key,
    Model value, {
    bool? merge,
  }) async {
    var record = await _storeRecord(key);
    if (record != null) {
      // Keep the index field (unless the value moves the record to another
      // index key).
      return await record.put(databaseClient, {
        path: key,
        ...value,
      }, merge: merge);
    }
    // New index key, create the record.
    var indexedValue = _indexedValue(key, value);
    await store.add(databaseClient, indexedValue);
    return indexedValue;
  }

  /// Update a record.
  ///
  /// If it does not exist, return null. if value is a map, keys with dot values
  /// refer to a path in the map, unless the key is specifically escaped
  ///
  /// Returns the updated value.
  Future<Model?> _clientUpdate(
    DatabaseClient databaseClient,
    K key,
    Model value,
  ) async => (await (await _storeRecord(key))?.update(databaseClient, value));

  /// Delete the record.
  Future _clientDelete(DatabaseClient databaseClient, K key) async =>
      (await (await _storeRecord(key))?.delete(databaseClient));
}
