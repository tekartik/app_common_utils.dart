import 'package:tekartik_app_cv/app_cv.dart';

/// Class that has parent map
abstract class CvFieldWithParent<T> implements CvField<T> {
  CvField<T> get field;

  String get parent;
}

class CvFieldWithParentImpl<
        T> //with CvColumnMixin<T>, ColumnNameMixin, CvFieldMixin<T>
    implements
        CvFieldWithParent<T> {
  @override
  final CvField<T> field;
  @override
  final String parent;

  CvFieldWithParentImpl(this.field, this.parent);

  @override
  T? get v => value;

  @override
  T? get value => field.value;

  @override
  CvField<RT> cast<RT>() => field.cast<RT>().withParent(parent);

  @override
  void clear() {
    field.clear();
  }

  @override
  void fromCvField(CvField cvField) {
    field.fromCvField(cvField);
  }

  @override
  bool get hasValue => field.hasValue;

  @override
  bool get isNull => field.isNull;

  @override
  bool get isTypeInt => field.isTypeInt;

  @override
  bool get isTypeString => field.isTypeString;

  @override
  String get k => key;

  @override
  String get key => '$parent.${field.name}';

  @override
  String get name => key;

  @override
  void removeValue() {
    // ignore: deprecated_member_use_from_same_package
    field.removeValue();
  }

  @override
  void setNull() {
    field.setNull();
  }

  @override
  void setValue(T? value, {bool presentIfNull = false}) {
    field.setValue(value, presentIfNull: presentIfNull);
  }

  @override
  Type get type => field.type;

  @override
  CvField<T> withParent(String parent) {
    // TODO: implement withParent
    throw UnimplementedError();
  }

  @override
  set v(T? value) {
    this.value = value;
  }

  @override
  set value(T? value) {
    field.value = value;
  }
}
