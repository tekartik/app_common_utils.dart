import 'package:tekartik_app_common_utils/common_utils_import.dart';
import 'package:tekartik_app_rx/auto_dispose.dart';

import 'state_base_bloc.dart';

/// Base bloc with auto dispose
abstract class AutoDisposeStateBaseBloc<T> extends StateBaseBloc<T>
    with AutoDisposeMixin, AutoDisposableMixin {
  @override
  @mustCallSuper
  void dispose() {
    audiDisposeAll();
    super.dispose();
  }

  @override
  void selfDispose() {
    dispose();
  }
}
