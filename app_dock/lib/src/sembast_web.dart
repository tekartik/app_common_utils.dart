import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart' show databaseFactoryWeb;

/// Sembast database factory (web).
///
/// [packageName] is ignored, the sembast database being an indexed db
/// database.
DatabaseFactory dockGetSembastDatabaseFactory({String? packageName}) {
  if (packageName == null) {
    return databaseFactoryWeb;
  } else {
    return databaseFactoryWeb.sandbox(path: packageName);
  }
}
