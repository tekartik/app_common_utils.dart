/// Define [dockGetSdbFactory] for a common support on VM and the web: the
/// local database of a pure Dart app (sembast files on io, IndexedDB on the
/// web).
library;

export 'package:idb_shim/sdb.dart';

export 'src/sdb.dart' show dockGetSdbFactory;
