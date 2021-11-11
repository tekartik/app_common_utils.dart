# tekartik_app_lints

Tekartik common lints

## Getting Started

### Setup

```yaml
dependencies:
  tekartik_app_lints:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      ref: dart2_3
      path: app_lints
    version: '>=0.1.0'
```

## Usage

In `analysis_options.yaml`:

```yaml
# tekartik recommended lints (extension over google lints and pedantic)
include: package:tekartik_app_lints/recommended.yaml
```