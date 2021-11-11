import 'package:sqflite_common/sqlite_api.dart';

DatabaseFactory get databaseFactory => _stub('databaseFactory');

DatabaseFactory getDatabaseFactory(
        {String? packageName, String? rootPath, bool autoInit = true}) =>
    databaseFactory;

/// Only needed/implemented on windows
void sqfliteWindowsFfiInit() => _stub('sqfliteWindowsFfiInit');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
