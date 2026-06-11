import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

import 'sembast.dart';

/// Prefs factory (io, sembast based).
///
/// If [packageName] is provided, prefs are stored in the application
/// databases directory (shared per user location on the file system),
/// otherwise they are relative to the current directory.
PrefsFactory dockGetPrefsFactory({String? packageName}) =>
    getPrefsFactorySembast(
      dockGetSembastDatabaseFactory(packageName: packageName),
      '.',
    );

/// Async prefs factory (io, sembast based).
///
/// If [packageName] is provided, prefs are stored in the application
/// databases directory (shared per user location on the file system),
/// otherwise they are relative to the current directory.
PrefsAsyncFactory dockGetPrefsAsyncFactory({String? packageName}) =>
    getPrefsAsyncFactorySembast(
      dockGetSembastDatabaseFactory(packageName: packageName),
      '.',
    );
