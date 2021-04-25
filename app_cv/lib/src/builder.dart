import 'package:tekartik_app_cv/app_cv.dart';

/// Global builder map
var _builders = <Type, Function(Map data)>{};

/// Add builder
void cvAddBuilder<T extends CvModel>(T Function(Map contextData) builder) {
  _builders[T] = builder;
}

/// Build a model but does not import the data.
T cvBuildModel<T extends CvModel>(Map contextData) {
  var builder = _builders[T];
  if (builder == null) {
    throw UnsupportedError('Missing builder for $T, call addBuilder');
  }
  return builder(contextData) as T;
}

/// Auto field
CvModelField<T> cvModelField<T extends CvModel>(String name) =>
    CvModelField<T>(name, (data) => cvBuildModel<T>(data as Map));

/// Auto field
CvModelListField<T> cvModelListField<T extends CvModel>(String name) =>
    CvModelListField<T>(name, (data) => cvBuildModel<T>(data as Map));

/// Easy extension
extension CvMapExt on Map {
  /// Create a DbRecord from a snapshot
  T cv<T extends CvModel>() {
    return cvBuildModel<T>(this)..fromModel(this);
  }
}

/// Easy extension
extension CvMapListExt on List<Map> {
  /// Create a list of DbRecords from a snapshot
  List<T> cv<T extends CvModel>() =>
      map((snapshot) => snapshot.cv<T>()).toList();
}
