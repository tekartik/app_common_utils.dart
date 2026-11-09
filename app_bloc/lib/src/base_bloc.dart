import 'package:tekartik_common_utils/common_utils_import.dart';

/// A minimal base for a bloc (or controller): it knows whether [dispose] was
/// called.
///
/// It closes nothing by itself: release your resources in [dispose], then
/// call `super.dispose()`.
class BaseBloc {
  var _disposed = false;

  /// Marks the bloc as disposed; an override must call `super.dispose()`.
  @mustCallSuper
  void dispose() {
    _disposed = true;
  }

  /// True once [dispose] was called: check it after an `await` before
  /// touching a closed controller.
  bool get disposed => _disposed;
}
