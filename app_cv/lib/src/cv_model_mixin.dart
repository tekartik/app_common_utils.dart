import 'package:tekartik_app_cv/app_cv.dart';
import 'package:tekartik_app_cv/src/cv_model.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_common_utils/model/model.dart';

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
        var entry = model.getModelEntry(field.name);
        if (entry != null) {
          if (field is CvFieldContentList) {
            var list = field.v = field.createList();
            for (var rawItem in entry.value as List) {
              var item = field.create(rawItem)..fromModel(rawItem as Map);
              list.add(item);
            }
            field.v = list;
          } else if (field is CvFieldContent) {
            var entryValue = entry.value;
            var cvModel = field.create(entryValue);
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
    columns ??= fields.map((e) => e.name).toList();
    var model = Model();
    for (var column in columns) {
      var field = this.field(column)!;
      dynamic value = field.v;
      if (value is List<CvModelCore>) {
        value = value.map((e) => (e as CvModelRead).toModel()).toList();
      }
      if (value is CvModelRead) {
        value = value.toModel(includeMissingValue: includeMissingValue);
      }
      model.setValue(field.name, value,
          presentIfNull: field.hasValue || includeMissingValue);
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
