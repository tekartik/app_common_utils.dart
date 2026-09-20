---
name: tekartik-app-text-search
description: >-
  Use when normalizing user text for search, ids or comparison with
  tekartik_app_text: removeDiacritics() on String from
  package:tekartik_app_text/diacritic.dart, sanitizeString/sanitizeText,
  SanitizedText (text, sanitizedString, compareTo) and its sanitizedWords
  extension from package:tekartik_app_text/sanitize.dart,
  SearchTextFinder(searchText:) with findIn/findAllIn from
  package:tekartik_app_text/search.dart, and stringSplitByWhitespace from
  package:tekartik_app_text/split.dart - accent insensitive, case insensitive
  matching and slug-like ids.
---

# Text sanitizing and search (tekartik_app_text)

`tekartik_app_text` normalizes free text so it can be compared, searched or
used as an id: accents removed, non alphanumeric runs collapsed, lower case.
`SearchTextFinder` builds a small accent/case insensitive matcher on top of it.

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
* Import only the library you need; there is no single umbrella library:
  `diacritic.dart`, `sanitize.dart`, `search.dart`, `split.dart` (and
  `sort.dart`, see [the sorting skill](../tekartik-app-text-sort/SKILL.md)).
* `String.removeDiacritics()` (extension `TekartikAppTextDiacriticsExt`, from
  `package:tekartik_app_text/diacritic.dart`) only strips accents: case,
  spaces and punctuation are untouched (`' Elève ?'` -> `' Eleve ?'`). Combine
  with `.toLowerCase()` for a plain comparison key.
* `sanitizeString(text)` from `package:tekartik_app_text/sanitize.dart` is the
  aggressive normalizer: trim, remove diacritics, replace every run of non
  `[a-zA-Z0-9]` characters with a single `_`, drop a leading/trailing `_`,
  lower case. `' Hello (world)'` -> `'hello_world'`, `' élè\t\nve ?-\r'` ->
  `'ele_ve'`. Use it for slug-like database ids and as a comparison key.
  Warning (as the doc comment says): it is lossy, different texts can produce
  the same string, so never use it as a unique key without a disambiguator.
  Non latin scripts collapse to an empty string.
* `sanitizeText(text)` returns a `SanitizedText` holding both `text` (the
  original) and `sanitizedString`. `sanitizedText.sanitizedWords` (extension
  `SanitizedTextExt`) splits the sanitized string on `_`, which is the word
  list used for searching. Keep the `SanitizedText` around when you need to
  display the original text next to the normalized key.
* `SanitizedText` gotcha: `compareTo` compares `sanitizedString` (so a sorted
  list is accent/case insensitive), but `==` compares the **original** `text`
  while `hashCode` is the `sanitizedString` hash. Two values with the same
  sanitized string are unequal yet share a hash bucket - fine for a `Set`, but
  do not rely on it for deduplication; deduplicate on `sanitizedString`
  yourself.
* `SearchTextFinder(searchText: input)` from
  `package:tekartik_app_text/search.dart` sanitizes the query once; build it
  once per query and reuse it for every candidate (in a list filter, a
  `where`, a stream transform):
  * `findIn(text)` - **all** the search words must each be a substring of
    **some** word of `text`, in any order. `'ma el'` matches `'Elev ma'`. This
    is the "type a few words" behaviour for a search field.
  * `findAllIn(text)` - the whole sanitized query must appear as a substring of
    the sanitized text, so word order and adjacency matter: `'ma el'` does not
    match `'Elev ma'` but matches `'ma Elev mca'`.
  * an empty or blank `searchText` makes both return true for every text:
    check `searchText.trim().isEmpty` first if an empty query should show
    everything (or nothing) explicitly.
* `stringSplitByWhitespace(input)` from `package:tekartik_app_text/split.dart`
  trims, splits on `\s+` and returns `[]` for an empty/blank string - unlike
  `input.split(' ')`, it never returns empty words. Punctuation is kept
  (`', Hello world'` -> `[',', 'Hello', 'world']`); use `sanitizedWords` when
  punctuation must go too.
* Pure Dart with no io: it runs on the VM, Flutter and the web (the package is
  tested on vm and chrome, dart2js and dart2wasm). Sanitizing is a few regexp
  passes; cache the sanitized string of a list of items instead of
  recomputing it on every keystroke.
* Anti-patterns: calling `sanitizeString` on every item inside the filter
  callback of a search field; using `sanitizeString` output as a primary key;
  using `findAllIn` for a multi-word search field (users type words out of
  order); expecting `removeDiacritics()` to lower case.

## Examples

### Sanitize for an id and for comparison

```dart
import 'package:tekartik_app_text/diacritic.dart';
import 'package:tekartik_app_text/sanitize.dart';

void main() {
  // Accents only.
  print('café'.removeDiacritics()); // cafe
  print(' Elève ?'.removeDiacritics()); //  Eleve ?

  // Slug-like id.
  print(sanitizeString(' Hello (world)')); // hello_world
  print(sanitizeString(' élè\t\nve ?-\r')); // ele_ve

  // Keep the original next to the key.
  var sanitized = sanitizeText(' Hello ? world');
  print(sanitized.text); //  Hello ? world
  print(sanitized.sanitizedString); // hello_world
  print(sanitized.sanitizedWords); // [hello, world]
  print(sanitized); //  Hello ? world (toString is the original text)
}
```

### Filter a list with SearchTextFinder

```dart
import 'package:tekartik_app_text/search.dart';

class Product {
  final String name;

  Product(this.name);

  @override
  String toString() => name;
}

/// Build the finder once, apply it to every item.
List<Product> searchProducts(List<Product> products, String query) {
  if (query.trim().isEmpty) {
    return products; // An empty query matches everything.
  }
  var finder = SearchTextFinder(searchText: query);
  return products.where((product) => finder.findIn(product.name)).toList();
}

void main() {
  var products = [
    Product('Crème brûlée'),
    Product('Chocolate cream'),
    Product('Apple pie'),
  ];
  // Accent and case insensitive, words in any order.
  print(searchProducts(products, 'creme')); // [Crème brûlée]
  print(searchProducts(products, 'cream choco')); // [Chocolate cream]

  // findAllIn needs the words contiguous and in order.
  var finder = SearchTextFinder(searchText: 'ma el');
  print(finder.findIn('Elev   ma')); // true
  print(finder.findAllIn('Elev   ma')); // false
  print(finder.findAllIn('ma Elev   mca')); // true
}
```

### Cache the sanitized text of the searched items

```dart
import 'package:tekartik_app_text/sanitize.dart';
import 'package:tekartik_app_text/search.dart';
import 'package:tekartik_app_text/split.dart';

/// An item with its sanitized form computed once.
class Contact {
  final String name;
  final SanitizedText sanitized;

  Contact(this.name) : sanitized = sanitizeText(name);
}

void main() {
  var contacts = [
    Contact('Amélie Poulain'),
    Contact('Jean Dupont'),
  ].toList()..sort((a, b) => a.sanitized.compareTo(b.sanitized));

  // Search against the already sanitized string.
  var finder = SearchTextFinder(searchText: 'amelie');
  for (var contact in contacts) {
    if (finder.findIn(contact.sanitized.sanitizedString)) {
      print(contact.name); // Amélie Poulain
    }
  }

  // Split a raw query into words, keeping punctuation.
  print(stringSplitByWhitespace('  Amélie \t Poulain ')); // [Amélie, Poulain]
  print(stringSplitByWhitespace('   ')); // []
}
```
