import 'package:idb_shim/sdb.dart';

/// Sdb factory (web).
///
/// The database is an IndexedDB database, [packageName] prefixes its name.
SdbFactory dockGetSdbFactory({String? packageName}) {
  if (packageName == null) {
    return sdbFactoryWeb;
  } else {
    return sdbFactoryWeb.sandbox(path: packageName);
  }
}
