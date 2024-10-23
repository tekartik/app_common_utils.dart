import 'package:cv/cv.dart';
import 'package:tekartik_app_json_schema/json_schema.dart';
import 'package:tekartik_common_utils/list_utils.dart';

const _typeKey = 'type';

/// JSON shema using the cv package
abstract class CvJsonSchema extends CvModelBase {
  /// Description
  CvField<String> get description;

  /// Nullable
  CvField<bool> get nullable;

  /// Type
  CvField<JsonSchemaType> get type;
}

/// JSON schema extension
extension CvJsonSchemaExt on CvJsonSchema {
  /// Convert to JSON schema
  JsonSchema toJsonSchema() {
    switch (this) {
      case CvJsonSchemaBool _:
        return JsonSchema.boolean(
          description: description.v,
          nullable: nullable.v,
        );

      case CvJsonSchemaEnumString def:
        return JsonSchema.enumString(
          description: description.v,
          nullable: nullable.v,
          enumValues: def.enumValues.v!,
        );
      case CvJsonSchemaWithFormat def:
        return JsonSchema(
          def.type.v!,
          format: def.format.v,
          description: description.v,
          nullable: nullable.v,
        );

      case CvJsonSchemaList def:
        return JsonSchema.array(
          description: description.v,
          nullable: nullable.v,
          items: def.items.v!.toJsonSchema(),
        );
      case CvJsonSchemaMap def:
        return JsonSchema.object(
          description: description.v,
          nullable: nullable.v,
          properties: def.properties.v!
              .map((key, value) => MapEntry(key, value.toJsonSchema())),
          optionalProperties: def.optionalProperties,
        );
      default:
        throw UnsupportedError('Unsupported type: ${type.v}');
    }
  }

  /// Convert to JSON schema map
  Model toSchemaJsonMap() {
    return toMap();
  }
}

/// Boolean JSON schema
abstract class CvJsonSchemaBool implements CvJsonSchema {
  /// Constructor
  factory CvJsonSchemaBool({
    String? description,
    bool? nullable,
  }) =>
      _CvJsonSchemaBool(
          type: JsonSchemaType.boolean,
          description: description,
          nullable: nullable);
}

/// Integer JSON schema
abstract class CvJsonSchemaInt implements CvJsonSchema, CvJsonSchemaNum {
  /// Constructor
  factory CvJsonSchemaInt({
    String? description,
    bool? nullable,
    String? format,
  }) =>
      _CvJsonSchemaInt(
          type: JsonSchemaType.integer,
          description: description,
          nullable: nullable,
          format: format);
}

/// Number JSON schema
abstract class CvJsonSchemaNum implements CvJsonSchema, CvJsonSchemaWithFormat {
  /// Constructor
  factory CvJsonSchemaNum({
    String? description,
    bool? nullable,
    String? format,
  }) =>
      _CvJsonSchemaNum(
          type: JsonSchemaType.number,
          description: description,
          nullable: nullable,
          format: format);
}

/// String JSON schema
abstract class CvJsonSchemaString
    implements CvJsonSchema, CvJsonSchemaWithFormat {
  /// Constructor
  factory CvJsonSchemaString({
    String? description,
    bool? nullable,
    String? format,
  }) =>
      _CvJsonSchemaString(
          type: JsonSchemaType.string,
          description: description,
          nullable: nullable,
          format: format);
}

/// Enum String JSON schema
abstract class CvJsonSchemaEnumString implements CvJsonSchemaString {
  /// Enum values
  CvField<List<String>> get enumValues;

  /// Constructor
  factory CvJsonSchemaEnumString({
    String? description,
    bool? nullable,
    required List<String> enumValues,
  }) =>
      _CvJsonSchemaEnumString(
          type: JsonSchemaType.string,
          description: description,
          nullable: nullable,
          format: jsonSchemaFormatEnum,
          enumValues: enumValues);
}

/// List JSON schema
abstract class CvJsonSchemaList implements CvJsonSchema {
  /// items type
  CvModelField<CvJsonSchema> get items;

  /// Constructor
  factory CvJsonSchemaList({
    String? description,
    bool? nullable,
    required CvJsonSchema items,
  }) =>
      _CvJsonSchemaList(
          type: JsonSchemaType.array,
          description: description,
          nullable: nullable,
          items: items);
}

/// Map (Object) JSON schema
abstract class CvJsonSchemaMap implements CvJsonSchema {
  /// Properties
  CvModelMapField<CvJsonSchema> get properties;

  /// Optional properties
  CvListField<String> get required;

  /// Constructor
  factory CvJsonSchemaMap({
    String? description,
    bool? nullable,
    required Map<String, CvJsonSchema> properties,
    List<String>? optionalProperties,
  }) =>
      _CvJsonSchemaMap(
          type: JsonSchemaType.object,
          description: description,
          nullable: nullable,
          properties: properties,
          optionalProperties: optionalProperties);

  /// Optional properties getter
  List<String>? get optionalProperties;
}

/// Has format
abstract class CvJsonSchemaWithFormat implements CvJsonSchema {
  /// Format
  CvField<String> get format;
}

abstract class _CvJsonSchemaBase extends CvModelBase implements CvJsonSchema {
  _CvJsonSchemaBase({
    JsonSchemaType? type,
    String? description,
    bool? nullable,
  }) : super() {
    this.type.v = type;
    this.description.setValue(description);
    this.nullable.setValue(nullable);
  }
  @override
  final description = CvField<String>('description');
  @override
  final nullable = CvField<bool>('nullable');
  @override
  final type = CvField<JsonSchemaType>(_typeKey);

  @override
  CvFields get fields => [type, description, nullable];

  @override
  Map<String, Object?> toMap(
      {List<String>? columns, bool includeMissingValue = false}) {
    var columnsNoType = List.of(columns ?? fields.map((field) => field.name))
      ..remove(_typeKey);
    final map = super.toMap(
        columns: columnsNoType, includeMissingValue: includeMissingValue);
    if (type.v != null) {
      map[_typeKey] = type.v!.toJson();
    }
    return map;
  }
}

mixin _CvJsonSchemaWithFormatMixin implements _CvJsonSchemaBase {
  final format = CvField<String>('format');
}

class _CvJsonSchemaBool extends _CvJsonSchemaBase implements CvJsonSchemaBool {
  _CvJsonSchemaBool({
    super.type,
    super.description,
    super.nullable,
  });
}

class _CvJsonSchemaInt extends _CvJsonSchemaNum
    with _CvJsonSchemaWithFormatMixin
    implements CvJsonSchemaInt {
  _CvJsonSchemaInt({
    super.type,
    super.description,
    super.nullable,
    super.format,
  });
}

class _CvJsonSchemaNum extends _CvJsonSchemaWithFormatBase
    implements CvJsonSchemaNum {
  _CvJsonSchemaNum({
    super.type,
    super.description,
    super.nullable,
    super.format,
  });
}

class _CvJsonSchemaString extends _CvJsonSchemaWithFormatBase
    implements CvJsonSchemaString {
  _CvJsonSchemaString({
    super.type,
    super.description,
    super.nullable,
    super.format,
  });
}

class _CvJsonSchemaEnumString extends _CvJsonSchemaString
    implements CvJsonSchemaEnumString {
  _CvJsonSchemaEnumString({
    super.type,
    super.description,
    super.nullable,
    super.format,
    required List<String> enumValues,
  }) {
    this.enumValues.setValue(enumValues);
  }
  @override
  final enumValues = CvField<List<String>>('enum');

  @override
  CvFields get fields => [...super.fields, enumValues];
}

class _CvJsonSchemaWithFormatBase extends _CvJsonSchemaBase
    with _CvJsonSchemaWithFormatMixin
    implements CvJsonSchema, CvJsonSchemaWithFormat {
  _CvJsonSchemaWithFormatBase({
    super.type,
    super.description,
    super.nullable,
    String? format,
  }) : super() {
    this.format.setValue(format);
  }
  @override
  CvFields get fields => [...super.fields, format];
}

class _CvJsonSchemaList extends _CvJsonSchemaBase implements CvJsonSchemaList {
  _CvJsonSchemaList({
    super.type,
    super.description,
    super.nullable,
    required CvJsonSchema items,
  }) {
    this.items.setValue(items);
  }
  @override
  final items = CvModelField<CvJsonSchema>('items');

  @override
  CvFields get fields => [...super.fields, items];
}

List<String>? _mapKeysWithout(Model map, List<String>? without) {
  var list = List.of(map.keys);
  if (without != null) {
    list.removeWhere((key) => without.contains(key));
  }
  return list.nonEmpty();
}

class _CvJsonSchemaMap extends _CvJsonSchemaBase implements CvJsonSchemaMap {
  _CvJsonSchemaMap({
    super.type,
    super.description,
    super.nullable,
    required Map<String, CvJsonSchema> properties,
    List<String>? optionalProperties,
  }) {
    this.properties.setValue(properties);

    required.setValue(_mapKeysWithout(properties, optionalProperties));
  }
  @override
  final properties = CvModelMapField<CvJsonSchema>('properties');
  @override
  final required = CvListField<String>('required');

  @override
  CvFields get fields => [...super.fields, properties, required];

  @override
  List<String>? get optionalProperties {
    return _mapKeysWithout(properties.v!, required.v!);
  }
}
