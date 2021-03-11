import 'package:tekartik_app_cv/app_cv.dart';
import 'package:test/test.dart';
// ignore_for_file: unnecessary_statements

void main() {
  group('content_api_test', () {
    test('exports', () {
      [
        CvField,
        CvModelBase,
        CvModel,
        CvMapModel,
        CvModelListField,
        CvModelField,
        CvListField,
        cvValuesAreEqual,
      ];
    });
  });
}
