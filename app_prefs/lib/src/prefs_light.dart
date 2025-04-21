export 'package:tekartik_prefs/prefs.dart';
export 'package:tekartik_prefs/prefs_async.dart';

export 'prefs_light_io.dart'
    if (dart.library.js_interop) 'prefs_light_web.dart';
