---
name: tekartik-app-serialize-codegen
description: >-
  Use when generating fromMap/toMap serialization helpers for a plain Dart
  model class without build_runner, with tekartik_app_serialize:
  genSerializer(src:, type:) from
  package:tekartik_app_serialize/serialize.dart, run as a VM script or test, it
  reflects the class with dart:mirrors and writes a formatted
  <src-without-extension>.g.dart next to it declaring
  <entity>FromMap(map, {entity}) and <entity>ToMap(entity, {map}), honouring
  @JsonKey(name:) and @JsonKey(includeIfNull: false) from json_annotation.
---

# fromMap/toMap code generation (tekartik_app_serialize)

`tekartik_app_serialize` is a tiny, build_runner-free code generator: a VM
script reflects one class with `dart:mirrors` and writes the `fromMap`/`toMap`
pair next to the model file. The generated file is plain Dart with no runtime
dependency on this package.

## Guidelines

* Not on pub.dev, depend on it through git. It is a dev-time tool (the
  generated code imports only the model), so `dev_dependencies` is enough;
  `json_annotation` goes in the regular `dependencies` if the models use
  `@JsonKey`:
  ```yaml
  dependencies:
    json_annotation: any
  dev_dependencies:
    tekartik_app_serialize:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_serialize
      version: '>=0.1.0'
  ```
* The whole API is one function, from
  `package:tekartik_app_serialize/serialize.dart`:
  `Future genSerializer({required String src, required Type type})`.
  `src` is the path (relative to the current directory, so usually run from the
  package root) of the `.dart` file that **declares** `type`; the output is
  written to `<dirname(src)>/<basenameWithoutExtension(src)>.g.dart` and starts
  with `import '<basename(src)>';`, so `src` must really be the declaring file
  or the generated import will not resolve.
* It uses `dart:mirrors` (through `tekartik_app_mirrors`, see the
  `tekartik-app-mirrors-reflect` skill) and `dart:io`: run it with
  `dart run tool/generate_serializers.dart` or `dart test`, on the Dart VM
  only - never from Flutter, an AOT snapshot, or the web (`reflectClass` then
  throws `UnsupportedError`).
* Generated names come from the type name with the first letter lowercased
  (`Todo` -> `todoFromMap` / `todoToMap`):
  * `Todo todoFromMap(Map<String, dynamic> map, {Todo? todo})` - creates a
    `Todo()` when the optional named argument is omitted, otherwise fills the
    instance passed in (every field is assigned, so absent keys reset to null).
  * `Map<String, dynamic> todoToMap(Todo todo, {Map<String, Object?>? map})` -
    creates a new map, or adds the entries to the `map` passed in (useful to
    merge a discriminator or a parent's fields).
* Requirements on the model, all enforced only at compile time of the
  generated file:
  * every field must be **public, non-final, nullable** - the generator emits
    `entity.field = map['key'] as Type?;`, which does not compile for `final`,
    `late final`, private or non-nullable fields;
  * keep the types JSON-friendly (`int?`, `double?`, `num?`, `String?`,
    `bool?`, `Map?`, `List?`). The cast uses the declared type as-is, so
    `List<String>?` or `DateTime?` fields produce a cast that fails at runtime
    on decoded JSON. Convert those by hand after `fromMap`, or store them as
    primitives;
  * static fields are declarations too and would be emitted like instance
    fields - do not declare any in a serialized class;
  * getters/setters and methods are ignored (only `VariableMirror`
    declarations are visited).
* Only the declarations of the class **itself** are generated: inherited
  fields from a superclass are silently skipped (a `class Complex extends Base`
  generates nothing for `Base.base`). Either flatten the fields into one class,
  or call the parent's generated `...ToMap(parent, map: map)` /
  `...FromMap(map, parent: child)` by hand.
* `@JsonKey` from `package:json_annotation/json_annotation.dart` is the only
  metadata read, and only two of its options: `name:` renames the map key, and
  `includeIfNull: false` wraps the `toMap` assignment in a null check (the key
  is then absent from the map). Everything else (`defaultValue`, `fromJson`,
  `toJson`, `ignore`...) is ignored - no `@JsonSerializable`, no
  `part`/`part of`, no `build_runner`.
* The output is formatted with `dart_style` and written with the platform line
  ending, so the generated file is stable in git. Commit the `.g.dart` files
  and regenerate by re-running the script; a test that calls `genSerializer`
  and then exercises the committed helpers keeps them in sync (that is how the
  package tests itself).
* Anti-patterns: pointing `src` at a file that does not declare the type;
  editing the `.g.dart` by hand; expecting nested model objects or enums to be
  converted; running the generator from Flutter or web code; relying on it for
  a class with inherited state.

## Examples

### Generate the helpers for a model

```dart
// tool/generate_serializers.dart, run with:
//   dart run tool/generate_serializers.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:tekartik_app_serialize/serialize.dart';

// In a real project this class lives in the file passed as `src` and is
// imported here (import 'package:my_app/src/todo.dart';). It is inlined in
// this snippet so it stands alone.
class Todo {
  int? id;

  @JsonKey(name: 'due_date')
  String? dueDate;

  @JsonKey(includeIfNull: false)
  String? note;
}

Future<void> main() async {
  // Writes lib/src/todo.g.dart, starting with `import 'todo.dart';`.
  await genSerializer(src: 'lib/src/todo.dart', type: Todo);
}
```

### The generated file, and how to use it

```dart
// lib/src/todo.g.dart, as written by genSerializer. The real file starts with
// `import 'todo.dart';`; the model is inlined here so the snippet compiles.
class Todo {
  int? id;
  String? dueDate; // @JsonKey(name: 'due_date')
  String? note; // @JsonKey(includeIfNull: false)
}

Todo todoFromMap(Map<String, dynamic> map, {Todo? todo}) {
  todo ??= Todo();

  todo.id = map['id'] as int?;
  todo.dueDate = map['due_date'] as String?;
  todo.note = map['note'] as String?;

  return todo;
}

Map<String, dynamic> todoToMap(Todo todo, {Map<String, Object?>? map}) {
  map ??= <String, dynamic>{};

  map['id'] = todo.id;
  map['due_date'] = todo.dueDate;
  if (todo.note != null) {
    map['note'] = todo.note;
  }

  return map;
}

void main() {
  var todo = Todo()
    ..id = 1
    ..dueDate = '2024-01-01';
  // note is null and not included.
  print(todoToMap(todo)); // {id: 1, due_date: 2024-01-01}

  // Round trip.
  print(todoToMap(todoFromMap(todoToMap(todo))));

  // Fill an existing instance (every field is assigned, even missing keys).
  todoFromMap({'id': 2}, todo: todo);
  print(todo.dueDate); // null

  // Add the fields to an existing map.
  print(todoToMap(todo, map: <String, Object?>{'type': 'todo'}));
}
```

### Inherited fields are not generated

```dart
import 'package:tekartik_app_serialize/serialize.dart';

class Base {
  int? base;
}

class Complex extends Base {
  int? value;
}

Future<void> main() async {
  // test/src/extends.dart declares both classes.
  await genSerializer(src: 'test/src/extends.dart', type: Complex);

  // The generated complexToMap only writes {'value': ...}: `base` comes from
  // the superclass and is skipped. Flatten the field into Complex, or handle
  // the parent explicitly:
  //   var map = complexToMap(complex);
  //   map['base'] = complex.base;
}
```
