/// Define [dockGetPrefsFactory] and [dockGetPrefsAsyncFactory] for a common
/// support on VM and the web.
library;

export 'prefs_stub.dart'
    if (dart.library.js_interop) 'prefs_web.dart'
    if (dart.library.io) 'prefs_io.dart';
