import 'package:fs_shim/fs_browser.dart';
import 'package:path/path.dart' show url;

/// Application data path.
///
/// The web file system being a sandbox, this is the root directory or
/// a directory named after [packageName] if provided.
String dockGetAppDataPath({String? packageName}) =>
    packageName != null ? url.join(url.separator, packageName) : url.separator;

/// File system
FileSystem dockGetAppDataFileSystem({required String packageName}) =>
    fileSystemWeb.sandbox(path: dockGetAppDataPath(packageName: packageName));
