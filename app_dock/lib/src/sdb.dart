/// Define [dockGetSdbFactory] for a common support on VM and the web.
library;

export 'sdb_stub.dart'
    if (dart.library.js_interop) 'sdb_web.dart'
    if (dart.library.io) 'sdb_io.dart';
