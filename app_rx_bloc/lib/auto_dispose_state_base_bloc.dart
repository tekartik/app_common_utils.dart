/// [AutoDisposeStateBaseBloc]: a [StateBaseBloc] disposing the subjects,
/// subscriptions and inner blocs registered with the `audiAdd*` methods.
///
/// Re-exports `state_base_bloc.dart` and the auto dispose API of
/// `tekartik_app_rx` (not `AutoDisposeBaseBloc`).
library;

export 'package:tekartik_app_rx/auto_dispose.dart';

export 'src/auto_dispose_state_base_bloc.dart' show AutoDisposeStateBaseBloc;
export 'state_base_bloc.dart';
