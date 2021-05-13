import 'package:tekartik_app_cv/app_cv.dart';

import 'cv_model_mixin.dart';
import 'content_values.dart';

/// Read helper
abstract class CvModelRead implements CvModelCore {
  /// Convert to model
  Model toModel({List<String>? columns, bool includeMissingValue = false});

  /// Map alias
  Model toMap();
}

/// Write helper
abstract class CvModelWrite implements CvModelCore {
  /// Convert from model.
  void fromModel(Map map, {List<String>? columns});

  /// Map alias
  void fromMap(Map map);
}

/// Core model
abstract class CvModelCore {
  /// to override something like [name, description]
  List<CvField> get fields;

  /// CvField access
  CvField<T>? field<T>(String name);
}

/// Modifiable map.
abstract class CvMapModel implements CvModel, Map<String, dynamic> {
  /// Basic content values factory
  factory CvMapModel() => ContentValuesMap();

  /// Predefined fields, values can be changed but none can added.
  /// Usage discouraged unless you known the limitations.
  factory CvMapModel.withFields(List<CvField> list) {
    return ContentValues.withCvFields(list);
  }
}

/// Model to access the data
abstract class CvModel implements CvModelRead, CvModelWrite, CvModelCore {}

abstract class CvModelListRead {
  ModelList toModelList();
}

abstract class CvModelListWrite {
  void fromModelList(List map);
}

/// Base content class
abstract class CvModelBase with CvModelMixin {}

// ignore: unused_element
class _CvModelMock extends CvModelBase {
  @override
  List<CvField> get fields => throw UnimplementedError();
}
