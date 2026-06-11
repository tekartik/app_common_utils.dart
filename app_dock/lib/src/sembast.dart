/// Define [dockGetSembastDatabaseFactory] for a common support on VM and the web.
library;

import 'package:path/path.dart';
import 'package:tekartik_app_dock/fs.dart';

export 'sembast_stub.dart'
    if (dart.library.js_interop) 'sembast_web.dart'
    if (dart.library.io) 'sembast_io.dart';

/// Databases sub directory.
const dockSembastDatabasesDirPath = 'sembast_databases';

/// Application databases path (`databases` in the application data path).
String dockGetAppSembastDatabasesPath({String? packageName}) => join(
  dockGetAppDataPath(packageName: packageName),
  dockSembastDatabasesDirPath,
);
