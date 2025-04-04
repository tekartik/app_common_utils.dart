import 'package:tekartik_app_common_utils/auto_dispose.dart';
import 'package:tekartik_app_common_utils/common_utils_import.dart';

/// Best of both world with an ugly name
abstract class AutoDisposerable implements AutoDispose, AutoDisposable {}

/// Base class (good for controller)
abstract class AutoDisposerableBase
    with AutoDisposeMixin, AutoDisposableMixin
    implements AutoDisposable {
  @mustCallSuper
  @override
  void selfDispose() {
    audiDisposeAll();
  }
}
