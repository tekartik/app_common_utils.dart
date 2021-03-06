import 'package:tekartik_app_cv/app_cv.dart';
import 'package:test/test.dart';

import 'cv_model_test.dart';

void main() {
  group('cv', () {
    test('CvModel', () {
      var model = CvMapModel();
      model['test'] = 1;
    });

    test('toModelList', () async {
      expect([IntContent()].toModelList(), [{}]);

      expect([(IntContent()..value.v = 1)].toModelList(), [
        {'value': 1}
      ]);

      expect([{}].cv<IntContent>(builder: intContentBuilder), [IntContent()]);

      expect([{}].cv<IntContent>(builder: intContentBuilder), [IntContent()]);
    });
    test('CvModelList.cv', () async {
      expect([{}].cv<IntContent>(builder: intContentBuilder), [IntContent()]);

      expect(
          [
            {'value': 1}
          ].cv<IntContent>(builder: intContentBuilder),
          [IntContent()..value.v = 1]);
    });
    test('CvModelList no builder', () {
      expect(
          [
            {'value': 1}
          ].cv<NoBuilderIntContent>(builder: noBuilderIntContentBuilder),
          [IntContent()..value.v = 1]);
      try {
        [
          {'value': 1}
        ].cv<NoBuilderIntContent>();
      } on UnsupportedError catch (_) {}

      try {
        addNoBuilderIntContentBuilder();
        expect(
            [
              {'value': 1}
            ].cv<NoBuilderIntContent>(),
            [IntContent()..value.v = 1]);
      } finally {
        removeNoBuilderIntContentBuilder();
      }
    });
  });
}
