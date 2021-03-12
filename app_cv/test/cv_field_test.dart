import 'package:tekartik_app_cv/app_cv.dart';
import 'package:test/test.dart';

void main() {
  group('CvField', () {
    test('cvValuesAreEquals', () {
      expect(cvValuesAreEqual(null, false), isFalse);
      expect(cvValuesAreEqual(null, null), isTrue);
      expect(cvValuesAreEqual(1, 1), isTrue);
      expect(cvValuesAreEqual(1, 2), isFalse);
      expect(cvValuesAreEqual(1, 'text'), isFalse);
      expect(cvValuesAreEqual([1], [1]), isTrue);
      expect(cvValuesAreEqual([1], [2]), isFalse);
      expect(cvValuesAreEqual({'a': 'b'}, {'a': 'b'}), isTrue);
    });
    test('equals', () {
      expect(CvField('name'), CvField('name'));
      expect(CvField('name'), CvField('name', null));
      expect(CvField('name'), isNot(CvField.withValue('name', null)));
      expect(CvField('name'), isNot(CvField.withNull('name')));
      expect(CvField('name', 1), CvField('name', 1));
      expect(CvField('name', [1]), CvField('name', [1]));
      expect(CvField('name', {'a': 'b'}), CvField('name', {'a': 'b'}));
      expect(CvField('name', 1), isNot(CvField('name', 2)));
      expect(CvField('name'), isNot(CvField('name2')));
      expect(CvField('name'), isNot(CvField('name', 1)));
    });

    test('fromCvField', () {
      expect(CvField<String>('name')..fromCvField(CvField('name', 'value')),
          CvField('name', 'value'));
    });

    test('hasValue', () {
      var field = CvField('name');
      expect(field.hasValue, isFalse);
      expect(field.v, isNull);
      field.setNull();
      expect(field.hasValue, isTrue);
      expect(field.v, isNull);
      field.clear();
      expect(field.hasValue, isFalse);
      expect(field.v, isNull);
    });
  });
}
