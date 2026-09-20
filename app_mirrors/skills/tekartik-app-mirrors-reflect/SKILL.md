---
name: tekartik-app-mirrors-reflect
description: >-
  Use when a VM script, tool or code generator must reflect on a Dart class -
  list its fields, their types and their annotations - while the library is
  still importable from web/Flutter code, with tekartik_app_mirrors:
  reflectClass, MirrorSystem.getName, ClassMirror (declarations, superclass,
  reflectedType, hasReflectedType), DeclarationMirror (simpleName, metadata),
  VariableMirror, TypeMirror, InstanceMirror (reflectee, type), from
  package:tekartik_app_mirrors/mirrors.dart instead of dart:mirrors.
---

# Safe mirrors subset for code generation (tekartik_app_mirrors)

`tekartik_app_mirrors` re-declares the small part of `dart:mirrors` needed to
inspect a class (its fields, their types and their annotations) and resolves to
the real implementation only when `dart:io` is available. That makes
`package:tekartik_app_mirrors/mirrors.dart` importable from any project -
including web and Flutter code - where a direct `import 'dart:mirrors'` would
not compile.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_mirrors/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_mirrors:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_mirrors
      version: '>=0.1.0'
  ```
* Single import: `package:tekartik_app_mirrors/mirrors.dart`. Never import
  `dart:mirrors` (nor the package's `src/mirrors_vm.dart`) directly in shared
  code: that is the whole point of the package.
* Entry points: `ClassMirror reflectClass(Type key)` and the static
  `String MirrorSystem.getName(Symbol symbol)` (to turn a `simpleName` into a
  readable string). There is no `reflect(object)`, no method invocation, no
  instance creation - this is a read-only, declaration-level subset.
* Available surface, and nothing else: `ClassMirror` (`declarations`,
  `superclass`, `reflectedType`, `hasReflectedType`, `simpleName`,
  `metadata`), `DeclarationMirror` (`simpleName`, `metadata`),
  `VariableMirror` (adds `type`), `TypeMirror` (`reflectedType`,
  `hasReflectedType`), `InstanceMirror` (`reflectee`, `type`), plus the marker
  types `Mirror` and `ObjectMirror`. `qualifiedName`, `instanceMembers`,
  `isStatic`, `MethodMirror` etc. are *not* exposed.
* `declarations` only contains what the class itself declares (fields,
  getters, setters, constructors, ...), never inherited members: walk
  `superclass` (null on `Object`) to cover a hierarchy.
* Fields: filter `declarations.values` with `is VariableMirror`, then use
  `MirrorSystem.getName(declaration.simpleName)` for the name and
  `declaration.type.reflectedType` for the type. Guard with
  `type.hasReflectedType` before reading `reflectedType`, which throws
  `UnsupportedError` for a non instantiated generic.
* Annotations: `declaration.metadata` is a `List<InstanceMirror>`; the
  annotation object itself is `instanceMirror.reflectee`, so use a plain
  `is MyAnnotation` test on it (`reflectee` is `dynamic`).
* Platform reality: the implementation is selected by
  `if (dart.library.io)`, but the underlying `dart:mirrors` only works on the
  **JIT VM**. Use it from `dart run`/`dart test` scripts and generators. On
  the web (and anywhere the stub is picked) every call throws
  `UnsupportedError('Cannot reflectClass without dart:mirrors')`; under AOT
  (`dart compile exe`) or Flutter, `dart:mirrors` is unavailable. Mark tests
  with `@TestOn('vm')`.
* Because mirrors defeat tree shaking, keep them in build-time tools: generate
  Dart source (or a JSON description) once and commit it, rather than
  reflecting at runtime in an app.
* Anti-patterns: calling `reflectClass` in app/web code and only finding out
  at runtime; expecting `declarations` to include inherited fields; passing a
  typedef or `dynamic` to `reflectClass` (it throws `ArgumentError`);
  comparing `simpleName` symbols to strings without `MirrorSystem.getName`.

## Examples

### List the declared fields of a class

```dart
@TestOn('vm')
library;

import 'package:tekartik_app_mirrors/mirrors.dart';
import 'package:test/test.dart';

class Product {
  String? name;
  int? price;
  List<String>? tags;
}

List<String> fieldNames(Type type) {
  var classMirror = reflectClass(type);
  return [
    for (var declaration in classMirror.declarations.values)
      if (declaration is VariableMirror)
        MirrorSystem.getName(declaration.simpleName),
  ];
}

void main() {
  test('fields', () {
    var classMirror = reflectClass(Product);
    expect(classMirror.reflectedType, Product);
    expect(fieldNames(Product), ['name', 'price', 'tags']);

    for (var declaration in classMirror.declarations.values) {
      if (declaration is VariableMirror) {
        var type = declaration.type;
        print(
          '${MirrorSystem.getName(declaration.simpleName)}: '
          '${type.hasReflectedType ? type.reflectedType : '?'}',
        );
      }
    }
  });
}
```

### Read field annotations (the code generation use case)

```dart
import 'package:tekartik_app_mirrors/mirrors.dart';

/// Annotation declared like any other const class.
class Column {
  final String name;
  final bool optional;

  const Column(this.name, {this.optional = false});
}

class User {
  @Column('user_name')
  String? name;
  @Column('user_age', optional: true)
  int? age;
  // Not annotated: skipped below.
  String? ignored;
}

/// Maps a dart field name to its column name.
Map<String, Column> columns(Type type) {
  var result = <String, Column>{};
  for (var declaration in reflectClass(type).declarations.values) {
    if (declaration is VariableMirror) {
      for (var instanceMirror in declaration.metadata) {
        var reflectee = instanceMirror.reflectee;
        if (reflectee is Column) {
          result[MirrorSystem.getName(declaration.simpleName)] = reflectee;
        }
      }
    }
  }
  return result;
}

void main() {
  // Run on the JIT VM only (dart run), never compiled to exe or on the web.
  columns(User).forEach((field, column) {
    print('$field -> ${column.name} (optional: ${column.optional})');
  });
}
```

### Walk the superclass chain

```dart
import 'package:tekartik_app_mirrors/mirrors.dart';

class Base {
  int? id;
}

class Middle extends Base {
  String? label;
}

class Leaf extends Middle {
  bool? enabled;
}

/// Field names of the class and of all its ancestors, in declaration order.
List<String> allFieldNames(Type type) {
  var names = <String>[];
  ClassMirror? classMirror = reflectClass(type);
  while (classMirror != null && classMirror.reflectedType != Object) {
    for (var declaration in classMirror.declarations.values) {
      if (declaration is VariableMirror) {
        names.add(MirrorSystem.getName(declaration.simpleName));
      }
    }
    classMirror = classMirror.superclass;
  }
  return names;
}

void main() {
  print(allFieldNames(Leaf)); // [enabled, label, id]
  print(reflectClass(Leaf).superclass!.reflectedType); // Middle
}
```

### Generating a Dart source file from the reflected fields

```dart
import 'dart:io';

import 'package:tekartik_app_mirrors/mirrors.dart';

class Settings {
  String? theme;
  int? fontSize;
}

String generateToMap(Type type) {
  var classMirror = reflectClass(type);
  var typeName = classMirror.reflectedType.toString();
  var sb = StringBuffer();
  sb.writeln('extension ${typeName}MapExt on $typeName {');
  sb.writeln('  Map<String, Object?> toMap() => {');
  for (var declaration in classMirror.declarations.values) {
    if (declaration is VariableMirror) {
      var name = MirrorSystem.getName(declaration.simpleName);
      sb.writeln("    '$name': $name,");
    }
  }
  sb.writeln('  };');
  sb.writeln('}');
  return sb.toString();
}

/// `dart run tool/generate.dart [lib/src/settings_gen.dart]`
Future<void> main(List<String> args) async {
  var content = generateToMap(Settings);
  if (args.isEmpty) {
    print(content);
    return;
  }
  // Typically lib/src/generated/..., generated once and committed.
  await File(args.first).writeAsString(content);
}
```
