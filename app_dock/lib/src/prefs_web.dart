import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:tekartik_prefs_browser/prefs_async.dart';

/// Prefs factory (web, local storage based).
///
/// [packageName] is ignored on the web.
PrefsFactory dockGetPrefsFactory({String? packageName}) {
  if (packageName == null) {
    return prefsFactoryBrowser;
  } else {
    return prefsFactoryBrowser.sandbox(path: packageName);
  }
}

/// Async prefs factory (web, local storage based).
///
/// [packageName] is ignored on the web.
PrefsAsyncFactory dockGetPrefsAsyncFactory({String? packageName}) {
  if (packageName == null) {
    return prefsAsyncFactoryBrowser;
  } else {
    return prefsAsyncFactoryBrowser.sandbox(path: packageName);
  }
}
