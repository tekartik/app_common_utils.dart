/// Define [dockGetSembastDatabaseFactory] for a common support on VM and the web.
library;

export 'package:sembast/sembast.dart';
export 'package:sembast/sembast_io.dart';

export 'src/sembast.dart'
    show
        dockSembastDatabasesDirPath,
        dockGetAppSembastDatabasesPath,
        dockGetSembastDatabaseFactory;
