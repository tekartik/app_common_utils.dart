import 'package:fs_shim/fs_shim.dart';

/// Stub
FileSystem get fs => _stub('fs');

/// Stub
String dockGetAppDataPath({String? packageName}) => _stub('dockGetAppDataPath');

/// Stub
FileSystem dockGetAppDataFileSystem({required String packageName}) =>
    _stub('dockGetAppDataFileSystem');
T _stub<T>(String message) {
  throw UnimplementedError(message);
}
