import 'package:tekartik_app_bloc/base_bloc.dart';
import 'package:tekartik_app_common_utils/common_utils_import.dart';
import 'package:tekartik_app_rx/auto_dispose.dart';

/// Base bloc with auto dispose
abstract class AutoDisposeBaseBloc extends BaseBloc
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
