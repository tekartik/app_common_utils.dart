import 'package:tekartik_prefs/prefs.dart';
import 'package:tekartik_prefs/prefs_async.dart';

/// Stub
PrefsFactory dockGetPrefsFactory({String? packageName}) =>
    _stub('dockGetPrefsFactory');

/// Stub
PrefsAsyncFactory dockGetPrefsAsyncFactory({String? packageName}) =>
    _stub('dockGetPrefsAsyncFactory');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
