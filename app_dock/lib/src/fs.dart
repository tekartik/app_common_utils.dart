/// Define [fs], [dockGetAppDataPath] and [dockGetAppDatabasesPath] for a common
/// support on VM and the web.
library;

export 'fs_stub.dart'
    if (dart.library.js_interop) 'fs_web.dart'
    if (dart.library.io) 'fs_io.dart';
