import 'package:idb_shim/sdb.dart';

/// Sdb factory (web).
///
/// [packageName] is ignored, the sdb database being an indexed db database.
SdbFactory dockGetSdbFactory({String? packageName}) {
  if (packageName == null) {
    return sdbFactoryWeb;
  } else {
    return sdbFactoryWeb.sandbox(path: packageName);
  }
}
