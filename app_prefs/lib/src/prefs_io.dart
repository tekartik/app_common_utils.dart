import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs_sembast/prefs.dart';

/// Default for io use a local folder
PrefsFactory get prefsFactory => getPrefsFactory();

final _prefsFactoryMap = <String?, PrefsFactory>{};

PrefsFactory newPrefsFactorySembast(String? packageName) {
  return getPrefsFactorySembast(
      getDatabaseFactory(packageName: packageName), '.');
}

/// Use sembast on linux and windows
PrefsFactory getPrefsFactory({String? packageName}) {
  var prefsFactory = _prefsFactoryMap[packageName];
  if (prefsFactory == null) {
    _prefsFactoryMap[packageName] =
        prefsFactory = newPrefsFactorySembast(packageName);
  }
  return prefsFactory;
}
