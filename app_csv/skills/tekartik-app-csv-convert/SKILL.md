---
name: tekartik-app-csv-convert
description: >-
  Use when converting between a CSV text with a header row and a
  List<Map<String, Object?>> with tekartik_app_csv: mapListToCsv (columns,
  nullValue, converter), csvToMapList, CsvToListConverter, ListToCsvConverter,
  FirstOccurrenceSettingsDetector, csvToMapListDefaultCsvSettingsDetector,
  csvExcelCompatibilityBom and the package:tekartik_app_csv/app_csv.dart
  import - exports, imports, spreadsheets.
---

# Map list <-> CSV (tekartik_app_csv)

`tekartik_app_csv` is a thin, Excel-friendly layer on `package:csv`: one
function turns a list of maps into CSV text (header row built from the keys)
and one turns CSV text with a header row back into a list of maps. Pure Dart,
so it runs on the VM, the web and Flutter.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_csv/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_csv:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_csv
  ```
* Single import: `package:tekartik_app_csv/app_csv.dart`, which exports
  `mapListToCsv`, `csvToMapList`, `csvToMapListDefaultCsvSettingsDetector`,
  `csvExcelCompatibilityBom`, and the `CsvToListConverter`,
  `ListToCsvConverter`, `FirstOccurrenceSettingsDetector` compatibility
  classes.
* `String mapListToCsv(List<Map> mapList, {ListToCsvConverter? converter,
  Object? nullValue = '', List<String>? columns})`:
  * The header is the union of the keys, in first-seen order; a key appearing
    only in a later map is appended as a new column and earlier rows are
    padded with `nullValue`.
  * `columns: ['id', 'name']` forces those columns first and guarantees they
    exist even when no map has the key; other keys follow in encounter order.
  * `nullValue` (default `''`) fills null values and missing cells.
  * Values are written by `package:csv`'s encoder: numbers and bools unquoted,
    anything else via `toString()` (a `Uint8List` becomes `"[1, 2, 3]"`), and
    fields containing `,`, quotes or newlines are quoted. Rows are separated
    by `\r\n`.
  * An empty list returns an empty string.
* `List<Map<String, Object?>> csvToMapList(String csv,
  {CsvToListConverter? converter})`:
  * The first row is the header; the following rows become maps. A CSV with
    only a header returns an empty list, and an empty string throws
    `UnsupportedError('csv cannot be empty')`.
  * **Every value comes back as a `String`** (or `''` for an empty cell): no
    number, bool or date parsing. Convert explicitly, for instance with
    `int.tryParse` / `double.tryParse` or the `parseInt`/`parseBool` helpers
    of `tekartik_common_utils`.
  * Rows shorter than the header throw a `RangeError`; sanitize or fix the
    input first.
  * The default converter handles `\r\n` and `\n` line endings and quoted
    fields containing newlines (Google Sheets / Excel exports).
* Converters: pass `converter: CsvToListConverter(fieldDelimiter: ';')` for
  semicolon files (common in French/German Excel exports).
  `CsvToListConverter` also accepts `eol:` and `csvSettingsDetector:` for
  source compatibility with older code, but line endings are auto-detected by
  the decoder. `csvToMapListDefaultCsvSettingsDetector` is the default
  `FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n'], textDelimiters:
  ['"', "'"])` kept for the same reason. `ListToCsvConverter()` is const and
  `convert(List<List>)` gives raw row-level encoding when you do not want the
  map API.
* Excel: write the file as UTF-8 prefixed with `csvExcelCompatibilityBom`
  (a `Uint8List` BOM) so Excel shows accented characters correctly.
  `csvToMapList` tolerates a BOM-prefixed string on the way back only if you
  strip it - decode the bytes with `utf8.decode` and remove the leading
  `﻿` if your source may contain one.
* Anti-patterns: expecting typed values from `csvToMapList`; relying on key
  order across maps with different shapes instead of passing `columns:`;
  hand-joining strings with commas instead of using the converters (quoting
  bugs); feeding a header-less CSV to `csvToMapList`.

## Examples

### Round trip

```dart
import 'package:tekartik_app_csv/app_csv.dart';

void main() {
  var list = <Map<String, Object?>>[
    {'id': 1, 'name': 'Alice', 'note': 'likes "csv", a lot'},
    {'id': 2, 'name': 'Bob', 'extra': true},
  ];
  var csv = mapListToCsv(list);
  print(csv);
  // id,name,note,extra
  // 1,Alice,"likes ""csv"", a lot",
  // 2,Bob,,true

  var back = csvToMapList(csv);
  print(back.first['id']); // '1' as a String
  print(int.parse(back.first['id'] as String) + 1); // 2
}
```

### Stable column order and a custom empty value

```dart
import 'package:tekartik_app_csv/app_csv.dart';

void main() {
  var rows = <Map<String, Object?>>[
    {'name': 'Alice'},
    {'name': 'Bob', 'email': 'bob@example.com'},
  ];
  // 'id' and 'email' always present, in this order, missing cells as 'n/a'.
  print(mapListToCsv(rows, columns: ['id', 'email', 'name'], nullValue: 'n/a'));
  // id,email,name
  // n/a,n/a,Alice
  // n/a,bob@example.com,Bob
}
```

### Semicolon separated import, typed back

```dart
import 'package:tekartik_app_csv/app_csv.dart';

class Product {
  final String sku;
  final double price;

  Product(this.sku, this.price);

  @override
  String toString() => '$sku: $price';
}

List<Product> parseProducts(String csv) {
  var mapList = csvToMapList(
    csv,
    converter: CsvToListConverter(fieldDelimiter: ';'),
  );
  return mapList
      .map(
        (map) => Product(
          map['sku'] as String,
          double.tryParse(map['price'] as String? ?? '') ?? 0,
        ),
      )
      .toList();
}

void main() {
  print(parseProducts('sku;price\r\nA-1;12.5\r\nA-2;7'));
  // [A-1: 12.5, A-2: 7.0]
}
```

### Write an Excel friendly file (dart:io)

```dart
import 'dart:convert';
import 'dart:io';

import 'package:tekartik_app_csv/app_csv.dart';

Future<void> main() async {
  var csv = mapListToCsv(<Map<String, Object?>>[
    {'city': 'Genève', 'count': 3},
  ]);
  await File('out.csv').writeAsBytes([
    ...csvExcelCompatibilityBom,
    ...utf8.encode(csv),
  ]);

  // Reading back: drop the BOM before parsing.
  var text = utf8.decode(await File('out.csv').readAsBytes());
  if (text.startsWith('﻿')) {
    text = text.substring(1);
  }
  print(csvToMapList(text));
}
```
