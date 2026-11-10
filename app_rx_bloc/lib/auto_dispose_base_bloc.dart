/// [AutoDisposeBaseBloc]: a bloc disposing the subjects, subscriptions and
/// inner blocs registered with the `audiAdd*` methods.
///
/// Re-exports the auto dispose API of `tekartik_app_rx` (and rxdart).
library;

export 'package:tekartik_app_rx/auto_dispose.dart';

export 'src/auto_dispose_base_bloc.dart' show AutoDisposeBaseBloc;
