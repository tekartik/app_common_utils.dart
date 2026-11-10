/// Define [dockGetSembastDatabaseFactory] for a common support on VM and the
/// web, for existing sembast databases: new local databases use
/// `package:tekartik_app_dock/sdb.dart`.
library;

export 'package:sembast/sembast.dart';
export 'package:sembast/sembast_io.dart';

export 'src/sembast.dart'
    show
        dockSembastDatabasesDirPath,
        dockGetAppSembastDatabasesPath,
        dockGetSembastDatabaseFactory;
