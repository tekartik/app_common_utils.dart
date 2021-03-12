import 'package:collection/collection.dart';
import 'package:tekartik_app_cv/app_cv.dart';

import 'field.dart';

/// If 2 values are equals, entering nested list/map if any.
bool cvValuesAreEqual(dynamic v1, dynamic v2) {
  try {
    return DeepCollectionEquality().equals(v1, v2);
  } catch (_) {
    return v1 == v2;
  }
}

/// Basic CvField
abstract class CvField<T> implements CvFieldCore<T> {
  /// Only set value if not null
  factory CvField(String name, [T? value]) => CvFieldImpl(name, value);

  /// Force a null value
  factory CvField.withNull(String name) => CvFieldImpl.withNull(name);

  /// Force a value event if null
  factory CvField.withValue(String name, T value) =>
      CvFieldImpl.withValue(name, value);
}

/// Nested list of raw values
abstract class CvListField<T> implements CvField<List<T>> {
  /// List create helper
  List<T> createList();

  /// Only set value if not null
  factory CvListField(String name) => ListCvFieldImpl<T>(name);
}

/// Nested model
abstract class CvModelField<T extends CvModel> implements CvField<T> {
  /// contentValue should be ignored
  T create(dynamic contentValue);

  /// Only set value if not null
  factory CvModelField(String name, T Function(dynamic contentValue) create) =>
      CvFieldContentImpl<T>(name, create);
}

/// Nested list
abstract class CvModelListField<T extends CvModel> implements CvField<List<T>> {
  /// contentValue should be ignored or could be used to create the proper object
  /// but its content should not be populated.
  T create(dynamic contentValue);

  List<T> createList();

  /// Only set value if not null
  factory CvModelListField(
          String name, T Function(dynamic contentValue) create) =>
      CvFieldContentListImpl<T>(name, create);
}
