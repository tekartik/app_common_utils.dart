import 'package:tekartik_app_rx_bloc/auto_dispose_base_bloc.dart';
import 'package:test/test.dart';

class TestBloc extends AutoDisposeBaseBloc {
  late var state = audiAddBehaviorSubject(BehaviorSubject.seeded(false));
}

class InnerBloc extends AutoDisposeBaseBloc {}

class OuterBloc extends AutoDisposeBaseBloc {
  late final innerBloc = audiAddDisposable(InnerBloc());
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
    test('inner bloc', () {
      var outerBloc = OuterBloc();
      expect(outerBloc.disposed, isFalse);
      expect(outerBloc.innerBloc.disposed, isFalse);
      outerBloc.dispose();
      expect(outerBloc.disposed, isTrue);
      expect(outerBloc.innerBloc.disposed, isTrue);
    });
  });
}
