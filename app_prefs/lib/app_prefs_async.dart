/// Async prefs (`PrefsAsync`) for the platform: sembast_sqflite files on io,
/// localStorage on the web.
library;

import 'package:tekartik_prefs/prefs_async.dart';

import 'src/prefs.dart' as src;

export 'package:tekartik_prefs/prefs_async.dart';

/// The prefs factory without package name.
///
/// On io the prefs are in `.dart_tool/sqflite_common_ffi/databases` of the
/// current directory: use [getPrefsAsyncFactory] with a package name in a
/// program.
PrefsAsyncFactory get prefsAsyncFactory => src.prefsAsyncFactory;

/// The prefs factory of [packageName], cached (the same factory for the same
/// package name).
///
/// On io (Linux, macOS, Windows) the prefs are in
/// `<userAppDataPath>/<packageName>/databases`; ignored on the web.
PrefsAsyncFactory getPrefsAsyncFactory({String? packageName}) =>
    src.getPrefsAsyncFactory(packageName: packageName);
