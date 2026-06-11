/// Define [dockGetPrefsFactory] and [dockGetPrefsAsyncFactory] for a common
/// support on VM and the web.
library;

export 'package:tekartik_prefs/prefs.dart';
export 'package:tekartik_prefs/prefs_async.dart';

export 'src/prefs.dart' show dockGetPrefsAsyncFactory, dockGetPrefsFactory;
