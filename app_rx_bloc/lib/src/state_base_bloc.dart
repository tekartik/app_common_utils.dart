import 'package:rxdart/rxdart.dart';
import 'package:tekartik_app_bloc/base_bloc.dart';

class StateBaseBloc<T> extends BaseBloc {
  final _state = BehaviorSubject<T>();

  ValueStream<T> get state => _state.stream;

  void add(T state) {
    _state.sink.add(state);
  }

  @override
  void dispose() {
    _state.close();
    super.dispose();
  }
}
