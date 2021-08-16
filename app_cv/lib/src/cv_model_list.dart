import 'package:tekartik_app_cv/app_cv.dart';

/// List<CvModel> convenient extensions.
extension CvModelListExt<T extends CvModel> on List<T> {
  /// Convert to model list
  ModelList toModelList(
      {List<String>? columns, bool includeMissingValue = false}) {
    return ModelList(map((e) =>
        e.toModel(columns: columns, includeMissingValue: includeMissingValue)));
  }

  /// Convert to model list
  List<Map<String, Object?>> toMapList(
      {List<String>? columns, bool includeMissingValue = false}) {
    return ModelList(map((e) => e.toModel(
            columns: columns, includeMissingValue: includeMissingValue)))
        .cast<Map<String, Object?>>();
  }
}
