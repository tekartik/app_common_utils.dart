import 'package:tekartik_app_rx_bloc/auto_dispose_state_base_bloc.dart';
import 'package:test/test.dart';

class TestBloc extends AutoDisposeStateBaseBloc<String> {
  late var other = audiAddBehaviorSubject(BehaviorSubject.seeded(false));
}

void main() {
  group('auto_dispose_base_bloc', () {
    test('disposed', () {
      var bloc = TestBloc();
      expect(bloc.disposed, isFalse);
      expect(bloc.other.isClosed, isFalse);
      bloc.add('test');
      bloc.dispose();
      expect(bloc.disposed, isTrue);
      expect(bloc.other.isClosed, isTrue);
      expect(() => bloc.add('test2'), throwsA(isA<StateError>()));
    });
  });
}
