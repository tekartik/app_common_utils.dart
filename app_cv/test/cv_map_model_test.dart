import 'package:tekartik_app_cv/app_cv.dart';
import 'package:test/test.dart';

import 'cv_model_test.dart';

void main() {
  group('CvMapModel', () {
    test('fromMap', () {
      var cv = CvMapModel();
      cv['test'] = 1;
      expect(cv.toModel(), {'test': 1});
      cv = CvMapModel()..fromModel({'test': 1});
      expect(cv.toModel(), {'test': 1});
      cv.fromModel({'test': 2});
      expect(cv.toModel(), {'test': 2});
    });
    test('toModel', () {
      var cv = CvMapModel();
      cv['test'] = 1;
      expect(cv.toModel(columns: ['test']), {'test': 1});
      expect(cv.toModel(columns: []), {});
    });
    test('child content toModel', () {
      var cv = CvMapModel();
      cv['test'] = ChildContent()..sub.v = 'sub_v';
      expect(cv.toModel(columns: ['test']), {
        'test': {'sub': 'sub_v'}
      });
      expect(cv.toModel(columns: []), {});
    });
    test('child content list toModel', () {
      var cv = CvMapModel();
      cv['test'] = [ChildContent()..sub.v = 'sub_v'];
      expect(cv.toModel(columns: ['test']), {
        'test': [
          {'sub': 'sub_v'}
        ]
      });
      expect(cv.toModel(columns: []), {});
    });
    test('withFields', () {
      var cv = CvMapModel.withFields([CvField('test', 1)]);
      expect(cv.toModel(), {'test': 1});
      cv['test2'] = 1;
      cv['test'] = 2;

      //expect(cv.toModel(), {'test': 1, 'test2': 1});
      expect(cv.toModel(), {'test': 2});
    });
    test('map', () {
      var cv = CvMapModel();
      expect(cv.fields, []);
      cv['test'] = 1;
      expect(cv.fields, [CvField('test', 1)]);
      cv['test'] = null;
      expect(cv.fields, [CvField.withNull('test')]);
      expect(cv.toModel(), {'test': null});
      cv.field('test').v = 2;
      expect(cv.fields, [CvField('test', 2)]);
      expect(cv.toModel(), {'test': 2});
      cv.field('test').clear();
      expect(cv.fields, []);
      expect(cv.toModel(), {});
    });
  });
}
