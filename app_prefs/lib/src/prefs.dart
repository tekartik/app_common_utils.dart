export 'package:tekartik_prefs/prefs.dart';
export 'package:tekartik_prefs/prefs_async.dart';

export 'prefs_stub.dart'
    if (dart.library.js_interop) 'prefs_web.dart'
    if (dart.library.io) 'prefs_io.dart';
