import 'package:tekartik_app_bloc/base_bloc.dart';
import 'package:test/test.dart';

class TestBloc extends BaseBloc {}

void main() {
  group('base_bloc', () {
    test('disposed', () {
      var bloc = TestBloc();
      expect(bloc.disposed, isFalse);
      bloc.dispose();
      expect(bloc.disposed, isTrue);
    });
  });
}
