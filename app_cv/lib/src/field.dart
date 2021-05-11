import 'package:meta/meta.dart';
import 'package:tekartik_app_cv/app_cv.dart';

import 'column.dart';

/// CvField access
///
/// Use [v] for value access.
abstract class CvFieldCore<T> implements CvColumn<T> {
  /// The value (abbr.)
  T? get v;

  /// The value
  T? get value;

  /// The key (abbr.)
  String get k;

  /// The key (abbr.)
  String get key;

  /// Return true is null or unset
  bool get isNull;

  /// Set the value, even if null
  set v(T? value);

  /// Set the value, even if null.
  set value(T? value);

  /// Clear value and flag
  void clear();

  // to be deprecated use clear instead
  @deprecated
  void removeValue();

  /// [presentIfNull] true if null is marked as a value
  void setValue(T value, {bool presentIfNull = false});

  bool get hasValue;

  /// Allow dynamic CvFields
  @visibleForTesting
  void fromCvField(CvField CvField);

  /// Cast if needed
  CvField<RT> cast<RT>();

  /// Force the null value.
  void setNull();
}

/// Nested CvField content
abstract class CvFieldContent<T extends CvModel> implements CvField<T> {
  /// contentValue should be ignored
  T create(dynamic contentValue);

  /// Only set value if not null
  factory CvFieldContent(
          String name, T Function(dynamic contentValue) create) =>
      CvFieldContentImpl(name, create);
}

/// Nested list
abstract class CvFieldContentList<T extends CvModel>
    implements CvField<List<T>> {
  /// contentValue should be ignored or could be used to create the proper object
  /// but its content should not be populated.
  T create(dynamic contentValue);
  List<T> createList();

  /// Only set value if not null
  factory CvFieldContentList(
          String name, T Function(dynamic contentValue) create) =>
      CvFieldContentListImpl(name, create);
}

/// Nested list implementation.
class ListCvFieldImpl<T> extends CvFieldImpl<List<T>>
    implements CvField<List<T>>, CvListField<T> {
  @override
  List<T> createList() => <T>[];

  ListCvFieldImpl(String name) : super(name);
}

/// Nested list of object implementation.
class CvFieldContentListImpl<T extends CvModel> extends CvFieldImpl<List<T>>
    implements CvFieldContentList<T>, CvModelListField<T> {
  @override
  List<T> createList() => <T>[];
  final T Function(dynamic contentValue) _create;
  CvFieldContentListImpl(String name, this._create) : super(name);

  @override
  T create(contentValue) => _create(contentValue);
}

class CvFieldContentImpl<T extends CvModel> extends CvFieldImpl<T>
    implements CvFieldContent<T>, CvModelField<T> {
  final T Function(dynamic contentValue) _create;
  CvFieldContentImpl(String name, this._create) : super(name);

  @override
  T create(contentValue) => _create(contentValue);
}

class CvFieldImpl<T>
    with // order is important, 2020/11/08 last one wins!
        CvColumnMixin<T>,
        ColumnNameMixin,
        CvFieldMixin<T> {
  /// Only set value if not null
  CvFieldImpl(String name, [T? value]) {
    this.name = name;
    if (value != null) {
      v = value;
    }
  }

  /// Force a null value
  CvFieldImpl.withNull(String name) {
    this.name = name;
    _hasValue = true;
  }

  /// Set value even if null
  CvFieldImpl.withValue(String name, T value) {
    this.name = name;
    v = value;
  }
}

// ensure mixin compiles
// ignore: unused_element
class _TestCvField
    with ColumnNameMixin, CvColumnMixin, CvFieldMixin
    implements CvField {}

mixin CvFieldMixin<T> implements CvField<T> {
  T? _value;

  /// The value
  @override
  T? get v => _value;

  @override
  String get key => name;

  @override
  T? get value => _value;

  /// The key
  @override
  String get k => name;

  @override
  bool get isNull => _value == null;

  @override
  set v(T? value) {
    _hasValue = true;
    _value = value;
  }

  @override
  set value(T? value) => v == value;

  /// Clear value and flag
  @override
  void clear() {
    _value = null;
    _hasValue = false;
  }

  // to be deprecated use clear instead
  @override
  @deprecated
  void removeValue() {
    _value = null;
    _hasValue = false;
  }

  /// [presentIfNull] true if null is marked as a value
  @override
  void setValue(T? value, {bool presentIfNull = false}) {
    if (value == null) {
      if (presentIfNull) {
        v = value;
      } else {
        clear();
      }
    } else {
      v = value;
    }
  }

  bool _hasValue = false;

  @override
  bool get hasValue => _hasValue;

  /// Allow dynamic CvFields
  @override
  @visibleForTesting
  void fromCvField(CvField CvField) {
    setValue(CvField.v as T?, presentIfNull: CvField.hasValue);
  }

  @override
  String toString() => '$name: $v${(v == null && hasValue) ? ' (set)' : ''}';

  /// Cast if needed
  @override
  CvField<RT> cast<RT>() {
    if (this is CvField<RT>) {
      return this as CvField<RT>;
    }
    return CvField<RT>(name)..v = v as RT?;
  }

  @override
  int get hashCode => super.hashCode + (v?.hashCode ?? 0);

  @override
  bool operator ==(other) {
    if (other is CvField) {
      if (other.name != name) {
        return false;
      }
      if (other.hasValue != hasValue) {
        return false;
      }
      if (!cvValuesAreEqual(other.v, v)) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// Force the null value.
  @override
  void setNull() {
    setValue(null, presentIfNull: true);
  }
}

CvField<int> intCvField(String name) => CvField<int>(name);

CvField<String> stringCvField(String name) => CvField<String>(name);

/// List<Column> helpers
extension CvColumnExtension on List<CvColumn> {
  List<String> get names => map((c) => c.name).toList();
}
