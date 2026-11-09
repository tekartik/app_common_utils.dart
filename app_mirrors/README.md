# tekartik_app_mirrors

A read-only subset of `dart:mirrors` to list the fields of a class, their
types and their annotations from a VM tool or a code generator, in a
library that any project can import (web and Flutter included, where it
throws `UnsupportedError` at run time instead of failing to compile).

Deprecated: `dart:mirrors` is deprecated as of Dart 3.14, and so is
`package:tekartik_app_mirrors/mirrors.dart`. It keeps working on the VM (an
existing tool adds `// ignore: deprecated_member_use` on its import); new
code should generate its code (`build_runner`) instead.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_mirrors:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_mirrors
```

```dart
// ignore: deprecated_member_use
import 'package:tekartik_app_mirrors/mirrors.dart';

class User {
  String? name;
  int? age;
}

void main() {
  for (var declaration in reflectClass(User).declarations.values) {
    if (declaration is VariableMirror) {
      print(MirrorSystem.getName(declaration.simpleName)); // name, age
    }
  }
}
```

Platforms: it works on the Dart VM in JIT mode only (`dart run`,
`dart test`). On the web, in an AOT executable (`dart compile exe`) and in
Flutter, it compiles but every call throws `UnsupportedError`. See
[example/main.dart](example/main.dart) (annotations).

## What to use

* `reflectClass(type)`: a `ClassMirror` (`declarations`, `superclass`,
  `reflectedType`, `metadata`).
* `MirrorSystem.getName(symbol)`: the name of a `simpleName`.
* `VariableMirror` (a field, `type.reflectedType`), `InstanceMirror` (an
  annotation, `reflectee`).

## Common pitfalls

* `declarations` holds what the class declares, not the inherited members:
  walk `superclass` (null after `Object`).
* `reflectedType` throws for a generic type that is not instantiated: test
  `hasReflectedType` first.
* Before 2026-11-09 the implementation was picked when `dart:io` was there,
  so `dart compile exe` and Flutter builds of a program importing the
  library failed (`dart:mirrors` is not available on this platform).

## Agent skills

[skills/tekartik-app-mirrors-reflect](skills/tekartik-app-mirrors-reflect/SKILL.md).
