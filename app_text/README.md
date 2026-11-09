# tekartik_app_text

Text helpers for app lists and search fields, in pure Dart: accent and case
insensitive search (`SearchTextFinder`), a slug like key
(`sanitizeString('Crème (brûlée)')` is `creme_brulee`), natural sorting
(`item 2` before `item 10`), `removeDiacritics()` and a whitespace split.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_text:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_text
```

```dart
import 'package:tekartik_app_text/search.dart';
import 'package:tekartik_app_text/sort.dart';

void main() {
  var names = ['Zoé 10', 'zoe 2', 'Crème brûlée'];
  var finder = SearchTextFinder(searchText: 'creme'); // build once per query
  print(names.where(finder.findIn).toList()); // [Crème brûlée]
  print(names.toSortedBySmartTextList((name) => name));
  // [Crème brûlée, zoe 2, Zoé 10]
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser. No platform
setup. See [example/main.dart](example/main.dart).

## What to use

| Import | Main API | Use it to |
|---|---|---|
| `search.dart` | `SearchTextFinder(searchText:)`: `findIn` (every word, any order), `findAllIn` (the whole query, in order) | filter a list from a search field |
| `sort.dart` | `list.toSortedBySmartTextList(getText)`, `toSortedByAlphaNumericTextList`, `toSortedByTextList`, `List<String>.alphaNumericSort()` | sort for display, numbers in natural order |
| `sanitize.dart` | `sanitizeString`, `sanitizeText` (`SanitizedText`) | a comparison or search key, a slug |
| `diacritic.dart` | `String.removeDiacritics()` | strip accents only |
| `split.dart` | `stringSplitByWhitespace` | words of a text, no empty word |

## Common pitfalls

* Only `[a-zA-Z0-9]` survives sanitizing (after removing the accents): a
  Cyrillic, Greek or CJK text gives `''`, and a query made only of such
  letters or of punctuation (`'?'`, `'мир'`) matches every text, like an
  empty query. Check `sanitizeString(query).isEmpty` first.
* `sanitizeString` is lossy: different texts give the same key, never use
  it alone as a unique id.
* `alphaNumericSort()` sorts in place and is case sensitive (`Item 5`
  before `item 1`); the `toSortedBy...List` methods return a new list.
* A text without any letter or digit (`'!'`, `' - '`) threw a `RangeError`
  in `sanitizeString` and in `SearchTextFinder` before 2026-11-09.

## Agent skills

[skills/tekartik-app-text-search](skills/tekartik-app-text-search/SKILL.md)
(sanitize, search, split) and
[skills/tekartik-app-text-sort](skills/tekartik-app-text-sort/SKILL.md).
