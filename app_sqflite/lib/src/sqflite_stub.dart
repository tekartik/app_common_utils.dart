import 'package:sqflite_common/sqlite_api.dart';

/// All but Linux/Windows
DatabaseFactory get databaseFactory => _stub('databaseFactory');

DatabaseFactory getDatabaseFactory({
  String? packageName,
  String? rootPath,
  bool autoInit = true,
}) => _stub('getDatabaseFactory($packageName)');

/// Only needed/implemented on windows, safe on all platforms
void sqfliteWindowsFfiInit() => _stub('sqfliteWindowsFfiInit');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
