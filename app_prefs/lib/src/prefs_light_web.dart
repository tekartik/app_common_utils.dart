import 'package:sembast_web/sembast_web.dart';
import 'package:tekartik_prefs_sembast/prefs_light.dart';

/// PrefsLight for web
PrefsLight prefsLight = getPrefsLightSembast(
  databaseFactory: databaseFactoryWeb,
  path: 'prefs_light',
);
