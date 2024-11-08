import 'package:rxdart/rxdart.dart';
import 'package:tekartik_app_bloc/base_bloc.dart';

/// Base class for a state bloc
class StateBaseBloc<T> extends BaseBloc {
  final _state = BehaviorSubject<T>();

  /// Stream of the state
  ValueStream<T> get state => _state.stream;

  /// Add a new state
  void add(T state) {
    _state.sink.add(state);
  }

  /// Add an error
  void addError(Object error, [StackTrace? stackTrace]) {
    _state.sink.addError(error, stackTrace);
  }

  @override
  void dispose() {
    _state.close();
    super.dispose();
  }
}
