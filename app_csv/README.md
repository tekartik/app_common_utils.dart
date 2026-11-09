# tekartik_app_csv

Convert a list of maps to CSV text (a header row built from the keys) and
CSV text with a header row back to a list of maps. A thin, Excel friendly
layer on [csv](https://pub.dev/packages/csv).

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_csv:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_csv
```

```dart
import 'package:tekartik_app_csv/app_csv.dart';

void main() {
  var csv = mapListToCsv([
    {'id': 1, 'name': 'Alice'},
    {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'},
  ]);
  print(csv); // id,name,email\r\n1,Alice,\r\n2,Bob,bob@example.com
  print(csvToMapList(csv).last); // {id: 2, name: Bob, email: bob@example.com}
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser. See
[example/main.dart](example/main.dart).

## What to use

* `mapListToCsv(list, {columns, nullValue = '', converter})`: the header is
  the union of the keys in the order met (`columns` first and always
  present), missing and null values are `nullValue`, rows end with `\r\n`.
* `csvToMapList(csv, {converter})`: the first row is the header, every value
  is a `String`.
* `CsvToListConverter(fieldDelimiter: ';')`: a known field delimiter.
* `csvExcelCompatibilityBom`: the UTF-8 byte order mark to write first for
  Excel.

## Common pitfalls

* Values come back as strings (`'1'`, `'true'`): parse them yourself.
* Without `fieldDelimiter`, the delimiter is guessed from the first 10 lines
  (the most frequent of `,` `;` tab `|`), and the cells beyond the header
  are dropped: a one column file whose values contain `;` loses data. Pass
  the delimiter when you know it.
* A row shorter than the header gives `null` for the missing cells.
* `CsvToListConverter`'s `eol` and `csvSettingsDetector` are ignored (kept
  for old code): line endings are detected, only `"` quotes a field.
* An empty text throws `UnsupportedError`, a header only gives an empty
  list.

## Agent skills

[skills/tekartik-app-csv-convert](skills/tekartik-app-csv-convert/SKILL.md).
