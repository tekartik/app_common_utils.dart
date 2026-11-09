# tekartik_app_lints

An old set of lint rules for Dart apps: `package:lints/recommended.yaml`
plus a few rules (`always_declare_return_types`, `avoid_dynamic_calls`,
`unawaited_futures`, `prefer_single_quotes`...). No package of the tekartik
repositories uses it any more: for new code, use
[tekartik_lints](https://github.com/tekartik/common.dart/tree/main/packages/lints)
(`recommended.yaml`, `strict.yaml`), which this repository uses itself.

## Getting started

Not on pub.dev, add it as a git dev dependency (Dart SDK `^3.12.0`):

```yaml
dev_dependencies:
  tekartik_app_lints:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_lints
```

In `analysis_options.yaml`:

```yaml
include: package:tekartik_app_lints/recommended.yaml
```

Then `dart analyze`. Works for any Dart or Flutter package.

## Common pitfalls

* `recommended.yaml` still lists options and rules removed from Dart
  (`strong-mode: implicit-casts`, `iterable_contains_unrelated_type`,
  `list_remove_unrelated_type`, replaced by
  `collection_methods_unrelated_type` which `lints/recommended` has). They
  are ignored without warning (`included_file_warning: ignore`).
* The Dart files of `lib/src` and `tool/list_extra_pedantic_rules.dart` are
  not part of the lints (the tool reads the `.packages` file and the
  `pedantic` package, both gone).
