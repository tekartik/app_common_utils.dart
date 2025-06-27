import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:process_run/process_run.dart';
import 'package:sqflite_common/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

sqflite.DatabaseFactory get _defaultDatabaseFactory =>
    // ignore: invalid_use_of_visible_for_testing_member
    sqflite.databaseFactoryOrNull ?? ffi.databaseFactoryFfi;

/// All but Linux/Windows
sqflite.DatabaseFactory get databaseFactory => _defaultDatabaseFactory;

/// Use sqflite on any platform
sqflite.DatabaseFactory getDatabaseFactory({
  String? packageName,
  String? rootPath,
  bool autoInit = true,
}) {
  if (autoInit) {
    sqfliteWindowsFfiInit();
  }
  if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) &&
      (packageName != null || rootPath != null)) {
    return _DatabaseFactory(
      packageName: packageName,
      rootPath: rootPath,
      delegate: databaseFactory,
    );
  } else {
    return databaseFactory;
  }
}

void sqfliteWindowsFfiInit() => ffi.sqfliteFfiInit();

class _DatabaseFactory implements sqflite.DatabaseFactory {
  final String? packageName;
  final String? rootPath;
  final sqflite.DatabaseFactory delegate;
  late final String databasesPath;
  _DatabaseFactory({
    required this.packageName,
    required this.rootPath,
    required this.delegate,
  }) {
    databasesPath = packageName != null
        ? join(userAppDataPath, packageName, 'databases')
        : rootPath!;
  }

  String _fixPath(String path) {
    if (!isAbsolute(path)) {
      path = join(databasesPath, path);
    }
    return path;
  }

  String _fixAndCreatePath(String path) {
    path = _fixPath(path);
    try {
      var dir = Directory(dirname(path));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } catch (_) {}
    return path;
  }

  @override
  Future<bool> databaseExists(String path) =>
      delegate.databaseExists(_fixPath(path));

  @override
  Future<void> deleteDatabase(String path) =>
      delegate.deleteDatabase(_fixPath(path));

  @override
  Future<String> getDatabasesPath() async => databasesPath;

  @override
  Future<sqflite.Database> openDatabase(
    String path, {
    sqflite.OpenDatabaseOptions? options,
  }) => delegate.openDatabase(_fixAndCreatePath(path), options: options);

  @override
  Future<Uint8List> readDatabaseBytes(String path) =>
      delegate.readDatabaseBytes(_fixPath(path));

  @override
  Future<void> setDatabasesPath(String path) async {
    databasesPath = path;
  }

  @override
  Future<void> writeDatabaseBytes(String path, Uint8List bytes) =>
      delegate.writeDatabaseBytes(_fixAndCreatePath(path), bytes);
}
