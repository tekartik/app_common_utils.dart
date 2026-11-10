import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_prefs_sembast/prefs_light.dart';

/// PrefsLight for io: `.local/prefs_light/prefs.db` of the current directory.
PrefsLight prefsLight = getPrefsLightSembast(
  databaseFactory: databaseFactoryIo,
  path: join('.local', 'prefs_light'),
);
