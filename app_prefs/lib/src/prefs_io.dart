import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs_async.dart';

/// Default for io use a local folder
PrefsFactory get prefsFactory => getPrefsFactory();

/// Default for io use a local folder
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

/// Use sembast on linux and windows
PrefsFactory getPrefsFactory({String? packageName}) {
  var prefsFactory = _prefsFactoryMap[packageName];
  if (prefsFactory == null) {
    if (packageName == null) {
      return _defaultPrefsFactory ??= newPrefsFactorySembast(packageName);
    } else {
      _prefsFactoryMap[packageName] =
          prefsFactory = newPrefsFactorySembast(packageName);
    }
  }
  return prefsFactory;
}

/// Use sembast on linux and windows
PrefsAsyncFactory getPrefsAsyncFactory({String? packageName}) {
  var prefsFactory = _prefsAsyncFactoryMap[packageName];
  if (prefsFactory == null) {
    if (packageName == null) {
      prefsFactory =
          _defaultPrefsAsyncFactory ??= newPrefsAsyncFactorySembast(
            packageName: packageName,
          );
    } else {
      _prefsAsyncFactoryMap[packageName] =
          prefsFactory = newPrefsAsyncFactorySembast(packageName: packageName);
    }
  }
  return prefsFactory;
}
