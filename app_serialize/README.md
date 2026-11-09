# tekartik_app_serialize

A small `fromMap`/`toMap` code generator for plain Dart model classes,
without `build_runner`: a Dart VM script reflects the class with
`dart:mirrors` and writes `<file>.g.dart` next to the model. The generated
code is plain Dart, without dependency on this package.

**Deprecated**, as `dart:mirrors` (Dart 3.14): it keeps working on the Dart
VM, new code should generate its code with `build_runner`
(`json_serializable`) or use [cv](https://pub.dev/packages/cv) models.

## Getting started

Not on pub.dev, add it as a git dev dependency (Dart SDK `^3.12.0`), and
`json_annotation` if the models use `@JsonKey`:

```yaml
dependencies:
  json_annotation: any
dev_dependencies:
  tekartik_app_serialize:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_serialize
```

The model, in `lib/src/todo.dart`:

```dart
import 'package:json_annotation/json_annotation.dart';

class Todo {
  int? id;

  @JsonKey(name: 'due_date')
  String? dueDate;

  @JsonKey(includeIfNull: false)
  String? note;
}
```

A script, `tool/generate_serializers.dart`, run with
`dart run tool/generate_serializers.dart` from the package folder:

```dart
// ignore: deprecated_member_use
import 'package:tekartik_app_serialize/serialize.dart';
import 'package:my_app/src/todo.dart';

Future<void> main() async {
  // Writes lib/src/todo.g.dart: todoFromMap(map, {todo}) and
  // todoToMap(todo, {map}).
  await genSerializer(src: 'lib/src/todo.dart', type: Todo);
}
```

Dart VM only (`dart run`, `dart test`): `dart:mirrors` is not available in
AOT, Flutter and web builds. The generated file works everywhere. See
[example/main.dart](example/main.dart).

## Common pitfalls

* `src` must be the file that declares the type: the generated file
  imports it by its name.
* Every field must be public, non final and nullable (`int?`): the
  generated `entity.field = map['key'] as Type?;` does not compile
  otherwise. Static fields are generated too: keep them out of these
  classes.
* Inherited fields are skipped, only the class' own fields are generated.
* `@JsonKey(name:)` and `@JsonKey(includeIfNull: false)` are read, nothing
  else (`defaultValue`, `fromJson`...).
* The types are cast as declared: a `List<String>?` or `DateTime?` field
  fails at runtime on decoded JSON.

## Agent skills

[skills/tekartik-app-serialize-codegen](skills/tekartik-app-serialize-codegen/SKILL.md).
