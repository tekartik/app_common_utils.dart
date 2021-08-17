import 'package:cv/cv.dart';

export 'package:cv/cv.dart';

extension CvModelCompat on CvModel {
  /// Convert to map
  Model toModel({List<String>? columns, bool includeMissingValue = false}) =>
      toMap(columns: columns, includeMissingValue: includeMissingValue);

  /// Map alias
  void fromModel(Map map, {List<String>? columns}) =>
      fromMap(map, columns: columns);
}

extension CvModelListCompat<T extends CvModel> on List<T> {
  /// Convert to list
  List<Map<String, Object?>> toModelList(
          {List<String>? columns, bool includeMissingValue = false}) =>
      toMapList(columns: columns, includeMissingValue: includeMissingValue);
}
