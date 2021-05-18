import 'package:collection/collection.dart';
import 'package:tekartik_app_cv/app_cv.dart';
import 'cv_model.dart';
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

  /// List item type
  Type get itemType;

  /// Only set value if not null
  factory CvListField(String name) => ListCvFieldImpl<T>(name);
}

/// Field utils.
extension CvFieldUtilsExt<T> on CvField<T> {
  void fillField([CvFillOptions? options]) {
    options ??= CvFillOptions();
    if (this is CvListField) {
      (this as CvListField).fillList(options);
    } else if (this is CvModelField) {
      var modelValue = (this as CvModelField).create({})..fillModel(options);
      v = modelValue as T;
    } else if (options.valueStart != null) {
      v = generateBasicType(type, options) as T;
    } else {
      // Default to null
      v = null;
    }
  }
}

Object? generateBasicType(Type type, CvFillOptions options) {
  Object? v;
  if (options.valueStart != null) {
    var valueStart = options.valueStart! + 1;
    if (type == int) {
      v = valueStart;
    } else if (type == num) {
      v = valueStart.isEven ? valueStart : (valueStart + .5);
    } else if (type == double) {
      v = (valueStart + .5);
    } else if (type == String) {
      v = 'text_$valueStart';
    }
    if (v != null) {
      options.valueStart = valueStart;
    }
  }

  return v;
}

class CvFillOptions {
  int? collectionSize;
  int? valueStart;
  CvFillOptions({this.collectionSize, this.valueStart});
}

extension CvListFieldUtilsExt<T> on CvListField<T> {
  void fillList([CvFillOptions? options]) {
    options ??= CvFillOptions();
    var collectionSize = options.collectionSize;
    if (collectionSize == null) {
      value = null;
    } else {
      var list = createList();
      for (var i = 0; i < collectionSize; i++) {
        if (this is CvModelListField) {
          var item = (this as CvModelListField).create({}) as T;
          (item as CvModel).fillModel(options);
          list.add(item);
        } else if (this is CvListField<Map>) {
          if (options.valueStart != null) {
            print('map $this');
            var map = <String, Object?>{};
            for (var i = 0; i < collectionSize; i++) {
              map['field_$i'] = generateBasicType(int, options);
            }
            list.add(map as T);
          }
        } else if (this is CvListField<List>) {
          if (options.valueStart != null) {
            print('list $this');
            var subList = <Object?>[];
            for (var i = 0; i < collectionSize; i++) {
              subList.add(generateBasicType(int, options));
            }
            list.add(subList as T);
          }
        } else {
          if (options.valueStart != null) {
            print('item $this');
            list.add(generateBasicType(itemType, options) as T);
          }
        }
      }
      value = list;
    }
  }
}

extension CvModelFieldUtilsExt<T extends CvModel> on CvModelField<T> {
  /// Fill all null in model including leaves
  ///
  /// Fill list if listSize is set
  ///
  void fillModel([CvFillOptions? options]) {
    options ??= CvFillOptions();
    value = create({});
    value!.fillModel(options);
  }
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
abstract class CvModelListField<T extends CvModel> implements CvListField<T> {
  /// contentValue should be ignored or could be used to create the proper object
  /// but its content should not be populated.
  T create(dynamic contentValue);

  @override
  List<T> createList();

  /// Only set value if not null
  factory CvModelListField(
          String name, T Function(dynamic contentValue) create) =>
      CvFieldContentListImpl<T>(name, create);
}
