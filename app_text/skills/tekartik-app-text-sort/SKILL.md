---
name: tekartik-app-text-sort
description: >-
  Use when sorting strings or objects by a text in a natural, human order
  ("item 2" before "item 10") with tekartik_app_text: alphaNumericSort() on
  List<String> (TekartikAppSortTextExt) and, on List<T>
  (TekartikAppSortItemTextExt), toSortedByTextList(getText, compare),
  toSortedByAlphaNumericTextList(getText) and toSortedBySmartTextList(getText)
  which ignores case and diacritics, all from
  package:tekartik_app_text/sort.dart (compareNatural based).
---

# Natural text sorting (tekartik_app_text)

`package:tekartik_app_text/sort.dart` adds natural ("alpha numeric") sorting on
top of `package:collection`'s `compareNatural`, so `item 2` comes before
`item 10`, in place for a `List<String>` or by a key function for any list.

## Guidelines

* Not on pub.dev, depend on it through git (the package lives in the
  `app_text/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_text:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_text
      version: '>=1.0.0'
  ```
* One import: `package:tekartik_app_text/sort.dart` (extensions
  `TekartikAppSortTextExt` on `List<String>` and `TekartikAppSortItemTextExt<T>`
  on `List<T>`).
* `list.alphaNumericSort()` sorts a `List<String>` **in place** and returns
  nothing - do not write `var sorted = list.alphaNumericSort();`. It uses
  `compareNatural`, which is case and accent **sensitive**: `'Item 5'` sorts
  before `'item 1'` because uppercase letters come first.
* For a list of objects, the three methods return a **new** list and never
  modify the receiver:
  * `toSortedByTextList(getText, compare)` - full control, pass any
    `int Function(String, String)` (`compareNatural`, `compareAsciiLowerCase`,
    a locale aware comparator...);
  * `toSortedByAlphaNumericTextList(getText)` - `compareNatural` on the key;
  * `toSortedBySmartTextList(getText)` - the one to use for user facing lists:
    it applies `removeDiacritics()` and `toLowerCase()` to the key before
    `compareNatural`, so `['ze 2', 'Zé 1', 'Zé 10']` sorts as
    `['Zé 1', 'ze 2', 'Zé 10']`.
* `getText` is called once per item (the list is decorated, sorted, then
  undecorated), so an expensive key function is fine. The underlying
  `List.sort` is **not stable**: add a tie breaker in the key (or in the
  `compare` function of `toSortedByTextList`) when equal texts must keep a
  deterministic order.
* To sort `List<String>` without mutating it, either copy first
  (`var sorted = [...list]..alphaNumericSort();`) or use
  `list.toSortedBySmartTextList((text) => text)`.
* Natural order compares digit runs numerically: `item 1 via 3`, `item 1 via
  4`, `item 2`, `item 10`, `item 20 other`. It is not a locale collation - for
  full internationalized ordering use `intl`'s collation instead.
* Pure Dart, no io: VM, Flutter and web (the package is tested on vm and
  chrome, dart2js and dart2wasm).
* To sort by a normalized key you already computed, see
  [the search/sanitize skill](../tekartik-app-text-search/SKILL.md):
  `SanitizedText.compareTo` compares the sanitized (accent/case free) strings.
* Anti-patterns: assigning the result of `alphaNumericSort()`; calling
  `toSortedBy...List` inside a build/render loop instead of caching it;
  expecting stability or locale-aware ordering.

## Examples

### Sort a list of strings in place

```dart
import 'package:tekartik_app_text/sort.dart';

void main() {
  var list = <String>[
    'item 1 via 3',
    'item 2',
    'item 10',
    'Item 5',
    'item 1 via 4',
    'item 20 other',
  ];
  list.alphaNumericSort(); // in place, returns void
  print(list);
  // [Item 5, item 1 via 3, item 1 via 4, item 2, item 10, item 20 other]

  // Keep the original list untouched.
  var source = <String>['b 10', 'b 2', 'a 1'];
  var sorted = [...source]..alphaNumericSort();
  print(sorted); // [a 1, b 2, b 10]
}
```

### Sort objects by a text, ignoring case and diacritics

```dart
import 'package:tekartik_app_text/sort.dart';

class Song {
  final String title;
  final int year;

  Song(this.title, this.year);

  @override
  String toString() => title;
}

void main() {
  var songs = [Song('ze 2', 2020), Song('Zé 1', 2019), Song('Zé 10', 2021)];

  // Case and diacritic insensitive, natural number order.
  print(songs.toSortedBySmartTextList((song) => song.title));
  // [Zé 1, ze 2, Zé 10]

  // Raw natural order (case and accent sensitive).
  print(songs.toSortedByAlphaNumericTextList((song) => song.title));
  // [Zé 1, Zé 10, ze 2]

  // The source list is never modified.
  print(songs); // [ze 2, Zé 1, Zé 10]
}
```

### Custom comparator and tie breaker

```dart
import 'package:tekartik_app_text/diacritic.dart';
import 'package:tekartik_app_text/sort.dart';

class Track {
  final String name;
  final int index;

  Track(this.name, this.index);

  @override
  String toString() => '$name#$index';
}

void main() {
  var tracks = [Track('Été', 2), Track('ete', 1), Track('Hiver', 3)];

  // The sort is not stable: include a tie breaker in the key.
  var sorted = tracks.toSortedByTextList(
    (track) => '${track.name.removeDiacritics().toLowerCase()}/${track.index}',
    (a, b) => a.compareTo(b),
  );
  print(sorted); // [ete#1, Été#2, Hiver#3]

  // Plain descending order with a reversed comparator.
  print(
    tracks.toSortedByTextList((track) => track.name, (a, b) => b.compareTo(a)),
  );
}
```
