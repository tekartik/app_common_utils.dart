import 'package:tekartik_prefs/prefs.dart';

import 'src/prefs.dart' as src;

export 'package:tekartik_prefs/prefs.dart';

/// @Deprecated('use async')
/// The prefs factory to user
PrefsFactory get prefsFactory => src.prefsFactory;

/// @Deprecated('use async')
/// Support Windows and Linux desktop
PrefsFactory getPrefsFactory({String? packageName}) =>
    src.getPrefsFactory(packageName: packageName);
