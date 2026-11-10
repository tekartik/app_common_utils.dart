/// `prefsLight`, an always open key/value store: a sembast file
/// `.local/prefs_light/prefs.db` relative to the current directory on io,
/// sembast_web (IndexedDB) on the web.
library;

export 'package:tekartik_prefs/prefs_light.dart';
export 'src/prefs_light.dart' show prefsLight;
