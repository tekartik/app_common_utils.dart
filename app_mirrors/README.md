# Mirrors support

Code Generator running on the VM. Allows importing safely `mirrors.dart` in any project.

Deprecated: `dart:mirrors` is deprecated as of Dart 3.14, and so is
`package:tekartik_app_mirrors/mirrors.dart`. It keeps working on the VM (an
existing tool adds `// ignore: deprecated_member_use` on its import); new code
should generate its code (`build_runner`) instead.

## Setup

In your `pubspec.yaml`:

```yaml
dependencies:
  tekartik_app_mirrors:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_mirrors
    version: '>=0.1.0'
```
