# tekartik_app_dock

App dock for DartVM/web application: prefs, file system, sembast and sdb
factories with a common API on io and the web.

## Getting Started

### Setup

```yaml
dependencies:
  tekartik_app_dock:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_dock
    version: '>=0.1.0'
```

### Usage

```dart
import 'package:tekartik_app_dock/prefs.dart';
import 'package:tekartik_app_dock/sembast.dart';
import 'package:tekartik_app_dock/sdb.dart';
import 'package:tekartik_app_dock/fs.dart';

Future<void> main() async {
  // packageName is used on io to find a shared per user location on the
  // file system, it is ignored on the web.
  var packageName = 'com.example.my_app';

  // Prefs
  var prefsFactory = dbGetPrefsAsyncFactory(packageName: packageName);
  var prefs = await prefsFactory.openPreferences('my_prefs');

  // Sembast
  var databaseFactory = dbGetSembastDatabaseFactory(packageName: packageName);
  var db = await databaseFactory.openDatabase('my_database.db');

  // Sdb
  var sdbFactory = dbGetSdbFactory(packageName: packageName);

  // File system (io or indexed db based on the web)
  var dir = fs.directory(dbGetAppDataPath(packageName: packageName));
}
```
