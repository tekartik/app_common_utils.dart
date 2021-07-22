import 'package:tekartik_app_cv/app_cv.dart';
import 'package:tekartik_app_cv/src/cv_field_with_parent.dart';
import 'package:tekartik_app_cv/src/cv_model.dart';
import 'package:tekartik_common_utils/env_utils.dart';

import 'field.dart';
import 'utils.dart';

var debugContent = false; // devWarning(true);

/// Content mixin
mixin CvModelMixin implements CvModel {
  @override
  void fromModel(Map map, {List<String>? columns}) {
    _debugCheckCvFields();
    // assert(map != null, 'map cannot be null');
    columns ??= fields.map((e) => e.name).toList();
    var model = Model(map);
    for (var column in columns) {
      try {
        var field = this.field(column)!;
        ModelEntry? entry;

        if (field is CvFieldWithParent) {
          var parentModel = model;
          var parentField = field;
          while (true) {
            var child = parentModel.getValue(parentField.parent);
            if (child is Map) {
              parentModel = Model(child);
              var subField = parentField.field;
              if (subField is CvFieldWithParent) {
                parentField = subField;
              } else if (subField is CvFieldContent) {
                var modelEntry = parentModel.getModelEntry(subField.name);
                var modelEntryValue = modelEntry?.value;
                if (modelEntryValue is Map) {
                  entry = ModelEntry(
                      modelEntry!.key.toString(),
                      subField.create(modelEntryValue)
                        ..fromModel(modelEntryValue));
                }

                break;
                //subField.create(modelEntry)..fromModel(modelEntry)
              } else {
                entry = parentModel.getModelEntry(subField.name);
                break;
              }
            }
          }
        } else {
          entry = model.getModelEntry(field.name);
        }
        if (entry != null) {
          if (field is CvFieldContentList) {
            var list = field.v = field.createList();
            for (var rawItem in entry.value as List) {
              var item = field.create(rawItem as Map)..fromModel(rawItem);
              list.add(item);
            }
            field.v = list;
          } else if (field is CvFieldContent) {
            var entryValue = entry.value;
            var cvModel = field.create(entryValue as Map);
            field.v = cvModel;
            if (entryValue is Map) {
              cvModel.fromModel(entryValue);
            }
          } else if (field is CvListField) {
            var list = field.v = field.createList();
            for (var rawItem in entry.value as List) {
              list.add(rawItem);
            }
            field.v = list;
          } else {
            try {
              field.v = entry.value;
            } catch (_) {
              // Special string handling
              if (field.isTypeString) {
                field.v = entry.value?.toString();
              } else {
                rethrow;
              }
            }
          }
        }
      } catch (e) {
        if (debugContent) {
          print('ERROR fromModel($map, $columns) at $column');
        }
      }
    }
  }

  /// Copy content
  @override
  void copyFrom(CvModel model) {
    _debugCheckCvFields();
    for (var field in fields) {
      var recordCvField = model.field(field.name);
      if (recordCvField?.hasValue == true) {
        // ignore: invalid_use_of_visible_for_testing_member
        field.fromCvField(recordCvField!);
      }
    }
  }

  void _debugCheckCvFields() {
    if (isDebug) {
      var success = _debugCvFieldsCheckDone[runtimeType];

      if (success == null) {
        var _fieldNames = <String>{};
        for (var field in fields) {
          if (_fieldNames.contains(field.name)) {
            _debugCvFieldsCheckDone[runtimeType] = false;
            throw UnsupportedError(
                'Duplicated CvField ${field.name} in $runtimeType${fields.map((f) => f.name)} - $this');
          }
          _fieldNames.add(field.name);
        }
        _debugCvFieldsCheckDone[runtimeType] = success = true;
      } else if (!success) {
        throw UnsupportedError(
            'Duplicated CvFields in $runtimeType${fields.map((f) => f.name)} - $this');
      }
    }
  }

  @override
  Model toModel({List<String>? columns, bool includeMissingValue = false}) {
    _debugCheckCvFields();

    void _toModel(Model model, CvField field) {
      dynamic value = field.v;
      if (value is List<CvModelCore>) {
        value = value.map((e) => (e as CvModelRead).toModel()).toList();
      } else if (value is CvModelRead) {
        value = value.toModel(includeMissingValue: includeMissingValue);
      }
      if (field is CvFieldWithParent) {
        // Check sub model
        if (field.hasValue || includeMissingValue) {
          var subModel = model[field.parent] as Model?;
          if (!(subModel is Model)) {
            subModel = Model();
            model.setValue(field.parent, subModel);
          }
          // Try existing if any
          _toModel(subModel, field.field);
        }
      } else {
        model.setValue(field.name, value,
            presentIfNull: field.hasValue || includeMissingValue);
      }
    }

    var model = Model();

    if (columns == null) {
      for (var field in fields) {
        _toModel(model, field);
      }
    } else {
      for (var column in columns) {
        var field = this.field(column)!;
        _toModel(model, field);
      }
    }
    return model;
  }

  @override
  String toString() {
    try {
      return logTruncate('${toModel()}');
    } catch (e) {
      return logTruncate('$fields $e');
    }
  }

  // Only created if necessary
  Map<String, CvField>? _cvFieldMap;

  @override
  CvField<T>? field<T>(String name) {
    // Invalidate if needed
    if (_cvFieldMap != null) {
      if (_cvFieldMap!.length != fields.length) {
        _cvFieldMap = null;
      }
    }
    _cvFieldMap ??=
        Map.fromEntries(fields.map((field) => MapEntry(field.name, field)));
    return _cvFieldMap![name]?.cast<T>();
  }

  @override
  int get hashCode => fields.first.hashCode;

  @override
  bool operator ==(other) {
    if (other is CvModelRead) {
      return cvModelAreEquals(this, other);
    }
    return false;
  }

  @override
  void fromMap(Map map) => fromModel(map);

  @override
  Model toMap() => toModel();

  @override
  void clear() {
    for (var field in fields) {
      field.clear();
    }
  }
}

final _debugCvFieldsCheckDone = <Type, bool>{};
