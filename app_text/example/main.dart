// ignore_for_file: avoid_print

import 'package:tekartik_app_text/diacritic.dart';
import 'package:tekartik_app_text/sanitize.dart';
import 'package:tekartik_app_text/search.dart';
import 'package:tekartik_app_text/sort.dart';
import 'package:tekartik_app_text/split.dart';

void main() {
  var names = ['Zoé 10', 'zoe 2', 'Crème brûlée', 'Chocolate cream'];

  // A search field: accent and case insensitive, words in any order.
  var finder = SearchTextFinder(searchText: 'CREAM choco');
  print(names.where(finder.findIn).toList()); // [Chocolate cream]

  // A user facing sort: case and accent insensitive, numbers in order.
  print(names.toSortedBySmartTextList((name) => name));
  // [Chocolate cream, Crème brûlée, zoe 2, Zoé 10]

  // A slug like key (lossy: different texts can give the same key).
  print(sanitizeString(' Crème (brûlée) ')); // creme_brulee
  print('Crème'.removeDiacritics()); // Creme
  print(stringSplitByWhitespace('  a \t b ')); // [a, b]
}
