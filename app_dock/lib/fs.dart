/// File system and path helpers for a dart app (io file system on the VM,
/// indexed db based file system on the web).
library;

export 'package:fs_shim/fs_shim.dart';

export 'src/fs.dart' show dockGetAppDataPath, dockGetAppDataFileSystem;
