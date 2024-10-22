import 'package:tekartik_prefs_browser/prefs.dart';
import 'package:tekartik_prefs_browser/prefs_async.dart';

/// Browser prefs factory
PrefsFactory get prefsFactory => prefsFactoryBrowser;

/// Browser prefs factory
PrefsFactory getPrefsFactory({String? packageName}) => prefsFactory;

/// Browser prefs factory
PrefsAsyncFactory get prefsAsyncFactory => prefsAsyncFactoryBrowser;

/// Browser prefs factory
PrefsAsyncFactory getPrefsAsyncFactory({String? packageName}) =>
    prefsAsyncFactory;
