import 'dart:async';

import 'package:tekartik_app_common_utils/sequence_validator/sequence_validator.dart';
import 'package:test/test.dart';

void main() {
  group('sequence_validator', () {
    test('1', () async {
      var vtor = SequenceValidator(sequence: <int>[1]);
      var result = vtor.validate();
      expect(result, const TypeMatcher<Future>());
      expect(await result, true);

      // Press once more
      vtor.restart();
      result = vtor.validate();
      expect(result, const TypeMatcher<Future>());
      expect(vtor.validate(), false);
      expect(await result, false);
    });

    test('2', () async {
      var vtor = SequenceValidator(sequence: <int>[2]);
      expect(vtor.validate(0), false);
      var result = vtor.validate(0);
      expect(result, const TypeMatcher<Future>());
      expect(await result, true);
    });

    test('cancelled', () async {
      var vtor = SequenceValidator(sequence: <int>[2]);
      expect(vtor.validate(0), false);
      var result = vtor.validate(0);
      expect(result, const TypeMatcher<Future>());

      expect(vtor.validate(0), isFalse);
      expect(await result, isFalse);
    });

    test('2 groups success', () async {
      var vtor = SequenceValidator(sequence: <int>[1, 1]);
      expect(vtor.validate(0), isFalse);
      expect(await vtor.validate(501), isTrue);
    });

    test('2 groups failure', () async {
      var vtor = SequenceValidator(sequence: <int>[1, 1]);
      expect(vtor.validate(0), isFalse);
      expect(vtor.validate(0), isFalse);

      vtor = SequenceValidator(sequence: <int>[1, 1]);
      expect(vtor.validate(0), isFalse);
      expect(vtor.validate(500), isFalse);

      vtor = SequenceValidator(sequence: <int>[1, 1]);
      expect(vtor.validate(0), isFalse);
      var result = vtor.validate(501);
      expect(result, const TypeMatcher<Future>());

      expect(vtor.validate(500), isFalse);
      expect(await result, isFalse);
      /*
      var result = vtor.validate();
      expect(result, const TypeMatcher<Future>());
      expect(await result, true);

      // Press once more
      vtor.restart();
      result = vtor.validate();
      expect(result, const TypeMatcher<Future>());
      expect(vtor.validate(), false);
      expect(await result, false);

       */
    });

    test('2x2 groups success', () async {
      var vtor = SequenceValidator(sequence: <int>[2, 2]);
      expect(vtor.validate(0), isFalse);
      expect(vtor.validate(0), isFalse);
      expect(vtor.validate(501), isFalse);
      expect(await vtor.validate(501), isTrue);
    });
  });
}
