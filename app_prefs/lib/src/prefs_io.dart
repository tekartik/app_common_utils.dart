import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

/// No package name: `.dart_tool/sqflite_common_ffi/databases` of the current
/// directory.
PrefsFactory get prefsFactory => getPrefsFactory();

/// No package name: `.dart_tool/sqflite_common_ffi/databases` of the current
/// directory.
PrefsAsyncFactory get prefsAsyncFactory => getPrefsAsyncFactory();

final _prefsFactoryMap = <String, PrefsFactory>{};
final _prefsAsyncFactoryMap = <String, PrefsAsyncFactory>{};
PrefsFactory? _defaultPrefsFactory;
PrefsAsyncFactory? _defaultPrefsAsyncFactory;

/// Sembast prefs factory
PrefsFactory newPrefsFactorySembast(String? packageName) {
  return getPrefsFactorySembast(
    getDatabaseFactory(packageName: packageName),
    '.',
  );
}

/// Sembast prefs factory
PrefsAsyncFactory newPrefsAsyncFactorySembast({String? packageName}) {
  return getPrefsAsyncFactorySembast(
    getDatabaseFactory(packageName: packageName),
    '.',
  );
}

/// sembast_sqflite prefs files, in `<userAppDataPath>/<packageName>/databases`
/// with a package name, cached per package name.
PrefsFactory getPrefsFactory({String? packageName}) {
  var prefsFactory = _prefsFactoryMap[packageName];
  if (prefsFactory == null) {
    if (packageName == null) {
      return _defaultPrefsFactory ??= newPrefsFactorySembast(packageName);
    } else {
      _prefsFactoryMap[packageName] = prefsFactory = newPrefsFactorySembast(
        packageName,
      );
    }
  }
  return prefsFactory;
}

/// sembast_sqflite prefs files, in `<userAppDataPath>/<packageName>/databases`
/// with a package name, cached per package name.
PrefsAsyncFactory getPrefsAsyncFactory({String? packageName}) {
  var prefsFactory = _prefsAsyncFactoryMap[packageName];
  if (prefsFactory == null) {
    if (packageName == null) {
      prefsFactory = _defaultPrefsAsyncFactory ??= newPrefsAsyncFactorySembast(
        packageName: packageName,
      );
    } else {
      _prefsAsyncFactoryMap[packageName] = prefsFactory =
          newPrefsAsyncFactorySembast(packageName: packageName);
    }
  }
  return prefsFactory;
}
