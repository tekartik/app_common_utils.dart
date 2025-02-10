import 'package:tekartik_app_rx_bloc/auto_dispose_base_bloc.dart';
import 'package:test/test.dart';

class TestBloc extends AutoDisposeBaseBloc {
  late var state = audiAddBehaviorSubject(BehaviorSubject.seeded(false));
}

void main() {
  group('auto_dispose_base_bloc', () {
    test('disposed', () {
      var bloc = TestBloc();
      expect(bloc.disposed, isFalse);
      expect(bloc.state.isClosed, isFalse);
      bloc.dispose();
      expect(bloc.disposed, isTrue);
      expect(bloc.state.isClosed, isTrue);
    });
  });
}
