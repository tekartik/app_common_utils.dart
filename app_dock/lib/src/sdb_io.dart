import 'package:idb_shim/sdb.dart';
import 'package:tekartik_app_dock/sembast.dart';

final _factories = <String, SdbFactory>{};

/// Sdb factory (io, sembast based).
///
/// If [packageName] is provided, relative database paths are resolved in
/// the application databases directory (shared per user location on the
/// file system), otherwise they are relative to the current directory.
SdbFactory dockGetSdbFactory({String? packageName}) {
  if (packageName == null) {
    return sdbFactoryIo;
  }
  return _factories[packageName] ??= sdbFactoryIo.sandbox(
    path: dockGetAppSembastDatabasesPath(packageName: packageName),
  );
}
