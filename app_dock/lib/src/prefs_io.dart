import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

import 'sembast.dart';

/// One factory per package name: the sembast prefs factories keep their
/// opened prefs, two factories on the same files would give two prefs on one
/// database.
final _prefsFactories = <String?, PrefsFactory>{};
final _prefsAsyncFactories = <String?, PrefsAsyncFactory>{};

/// Prefs factory (io, sembast based).
///
/// If [packageName] is provided, prefs are stored in the application
/// databases directory (shared per user location on the file system),
/// otherwise they are relative to the current directory.
///
/// The same factory is returned for the same [packageName].
PrefsFactory dockGetPrefsFactory({String? packageName}) =>
    _prefsFactories[packageName] ??= getPrefsFactorySembast(
      dockGetSembastDatabaseFactory(packageName: packageName),
      '.',
    );

/// Async prefs factory (io, sembast based).
///
/// If [packageName] is provided, prefs are stored in the application
/// databases directory (shared per user location on the file system),
/// otherwise they are relative to the current directory.
///
/// The same factory is returned for the same [packageName].
PrefsAsyncFactory dockGetPrefsAsyncFactory({String? packageName}) =>
    _prefsAsyncFactories[packageName] ??= getPrefsAsyncFactorySembast(
      dockGetSembastDatabaseFactory(packageName: packageName),
      '.',
    );
