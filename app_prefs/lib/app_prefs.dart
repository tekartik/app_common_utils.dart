/// Legacy synchronous prefs (`Prefs`: reads from memory, writes saved in the
/// background) for the platform: sembast_sqflite files on io, localStorage on
/// the web. Prefer `app_prefs_async.dart` in new code.
library;

import 'package:tekartik_prefs/prefs.dart';

import 'src/prefs.dart' as src;

export 'package:tekartik_prefs/prefs.dart';

/// The prefs factory without package name (prefer the async API).
///
/// On io the prefs are in `.dart_tool/sqflite_common_ffi/databases` of the
/// current directory: use [getPrefsFactory] with a package name in a program.
PrefsFactory get prefsFactory => src.prefsFactory;

/// The prefs factory of [packageName] (prefer the async API), cached.
///
/// On io (Linux, macOS, Windows) the prefs are in
/// `<userAppDataPath>/<packageName>/databases`; ignored on the web.
PrefsFactory getPrefsFactory({String? packageName}) =>
    src.getPrefsFactory(packageName: packageName);
