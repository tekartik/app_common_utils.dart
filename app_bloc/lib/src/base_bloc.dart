import 'package:tekartik_common_utils/common_utils_import.dart';

class BaseBloc {
  var _disposed = false;
  @mustCallSuper
  void dispose() {
    _disposed = true;
  }

  bool get disposed => _disposed;
}
