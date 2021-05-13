import 'package:rxdart/rxdart.dart';
import 'package:tekartik_app_rx_bloc/src/state_base_bloc.dart';
import 'package:test/test.dart';

class TestBloc extends StateBaseBloc<String> {}

void main() {
  group('state_base_bloc', () {
    test('disposed', () {
      var bloc = TestBloc();
      expect(bloc.disposed, isFalse);
      bloc.dispose();
      expect(bloc.disposed, isTrue);
    });
    test('state', () {
      var bloc = TestBloc();
      expect(bloc.state.hasValue, isFalse);
      expect(() => bloc.state.value,
          throwsA(const TypeMatcher<ValueStreamError>()));
      bloc.add('test');
      expect(bloc.state.hasValue, isTrue);
      expect(bloc.state.value, 'test');
      bloc.dispose();
      expect(() => bloc.add('test2'), throwsA(const TypeMatcher<StateError>()));
    });
  });
}
