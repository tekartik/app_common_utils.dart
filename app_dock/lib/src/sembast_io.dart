import 'package:tekartik_app_dock/sembast.dart';

/// Sembast database factory (io).
///
/// If [packageName] is provided, relative database paths are resolved in
/// the application databases directory (shared per user location on the
/// file system), otherwise they are relative to the current directory.
DatabaseFactory dockGetSembastDatabaseFactory({String? packageName}) {
  if (packageName == null) {
    return databaseFactoryIo;
  } else {
    return databaseFactoryIo.sandbox(
      path: dockGetAppSembastDatabasesPath(packageName: packageName),
    );
  }
}
