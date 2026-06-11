import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';
import 'package:process_run/process_run.dart' show userAppDataPath;

/// Io file system.
FileSystem get fs => fileSystemIo;

/// Application data path.
///
/// If [packageName] is provided, a shared per user location is used
/// (userAppDataPath/packageName), otherwise paths are relative to the
/// current directory.
String dockGetAppDataPath({String? packageName}) =>
    packageName != null ? join(userAppDataPath, packageName) : '.';

/// File system
FileSystem dockGetAppDataFileSystem({required String packageName}) =>
    fileSystemIo.sandbox(path: dockGetAppDataPath(packageName: packageName));
