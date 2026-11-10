import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart' show databaseFactoryWeb;

/// Sembast database factory (web).
///
/// The database is an IndexedDB database, [packageName] prefixes its name.
DatabaseFactory dockGetSembastDatabaseFactory({String? packageName}) {
  if (packageName == null) {
    return databaseFactoryWeb;
  } else {
    return databaseFactoryWeb.sandbox(path: packageName);
  }
}
