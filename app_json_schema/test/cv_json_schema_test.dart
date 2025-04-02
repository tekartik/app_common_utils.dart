// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:tekartik_app_json_schema/cv_json_schema.dart';
import 'package:test/test.dart';

typedef SchemaType = JsonSchemaType;
typedef Schema = JsonSchema;

void _checkToJsonSchema(CvJsonSchema schema) {
  expect(schema.toJsonSchema().toJson(), schema.toSchemaJsonMap());
}

void main() {
  group('Schema Tests', () {
    // Test basic constructors and toJson() for primitive types
    test('Schema.boolean', () {
      final schema = CvJsonSchemaBool(
        description: 'A boolean value',
        nullable: true,
      );
      expect(schema.type.v, SchemaType.boolean);
      expect(schema.description.v, 'A boolean value');
      expect(schema.nullable.v, true);
      expect(schema.toSchemaJsonMap(), {
        'type': 'BOOLEAN',
        'description': 'A boolean value',
        'nullable': true,
      });
      _checkToJsonSchema(schema);
    });

    test('Schema.integer', () {
      final schema = CvJsonSchemaInt(format: 'int32');
      expect(schema.type.v, SchemaType.integer);
      expect(schema.format.v, 'int32');
      expect(schema.toSchemaJsonMap(), {'type': 'INTEGER', 'format': 'int32'});
      _checkToJsonSchema(schema);
    });

    test('Schema.number', () {
      final schema = CvJsonSchemaNum(format: 'double', nullable: false);
      expect(schema.type.v, SchemaType.number);
      expect(schema.format.v, 'double');
      expect(schema.nullable.v, false);
      expect(schema.toSchemaJsonMap(), {
        'type': 'NUMBER',
        'format': 'double',
        'nullable': false,
      });
      _checkToJsonSchema(schema);
    });

    test('Schema.string', () {
      final schema = CvJsonSchemaString();
      expect(schema.type.v, SchemaType.string);
      expect(schema.toSchemaJsonMap(), {'type': 'STRING'});
      _checkToJsonSchema(schema);
    });

    test('Schema.enumString', () {
      final schema = CvJsonSchemaEnumString(enumValues: ['value1', 'value2']);
      expect(schema.type.v, SchemaType.string);
      expect(schema.format.v, 'enum');
      expect(schema.enumValues.v, ['value1', 'value2']);
      expect(schema.toSchemaJsonMap(), {
        'type': 'STRING',
        'format': 'enum',
        'enum': ['value1', 'value2'],
      });
      _checkToJsonSchema(schema);
    });

    // Test constructors and toJson() for complex types
    test('Schema.array', () {
      final itemSchema = CvJsonSchemaString();
      final schema = CvJsonSchemaList(items: itemSchema);
      expect(schema.type.v, SchemaType.array);
      expect(schema.items.v, itemSchema);
      expect(schema.toSchemaJsonMap(), {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      });
      _checkToJsonSchema(schema);
    });

    test('Schema.object', () {
      final properties = {
        'name': CvJsonSchemaString(),
        'age': CvJsonSchemaInt(),
      };
      final schema = CvJsonSchemaMap(
        properties: properties,
        optionalProperties: ['age'],
      );
      expect(schema.type.v, SchemaType.object);
      expect(schema.properties.v, properties);
      expect(schema.optionalProperties, ['age']);
      expect(schema.toSchemaJsonMap(), {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING'},
          'age': {'type': 'INTEGER'},
        },
        'required': ['name'],
      });
      _checkToJsonSchema(schema);
    });

    test('Schema.object with empty optionalProperties', () {
      final properties = {
        'name': CvJsonSchemaString(),
        'age': CvJsonSchemaInt(),
      };
      final schema = CvJsonSchemaMap(properties: properties);
      expect(schema.type.v, SchemaType.object);
      expect(schema.properties.v, properties);
      expect(schema.toSchemaJsonMap(), {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING'},
          'age': {'type': 'INTEGER'},
        },
        'required': ['name', 'age'],
      });
    });
  });
}
