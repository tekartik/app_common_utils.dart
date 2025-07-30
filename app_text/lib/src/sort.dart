import 'package:collection/collection.dart';
import 'package:tekartik_app_text/diacritic.dart';

/// Sort a list in an alpha numeric way
extension TekartikAppSortTextExt on List<String> {
  /// Sort a list in an alpha numeric way
  /// example:
  /// - item 1 via 3
  /// - item 1 via 4
  /// - item 2
  /// - item 10
  /// - item 20 other
  void alphaNumericSort() {
    sort(compareNatural);
  }
}

class _SortWrapper<T> {
  final T item;
  final String text;

  _SortWrapper(this.item, this.text);
}

/// Sorted list of items by text
extension TekartikAppSortItemTextExt<T> on List<T> {
  /// Sorted list of items by text
  List<T> toSortedByTextList(
    String Function(T item) getText,
    int Function(String a, String b) compare,
  ) {
    var list = map((item) => _SortWrapper(item, getText(item))).toList();
    list.sort((a, b) => compare(a.text, b.text));
    return list.map((item) => item.item).toList();
  }

  /// Sorted list of items by text
  List<T> toSortedByAlphaNumericTextList(String Function(T item) getText) =>
      toSortedByTextList(getText, compareNatural);

  /// Sorted list of items by text no case, no diacritics, alpha numeric sort
  List<T> toSortedBySmartTextList(String Function(T item) getText) =>
      toSortedByTextList(
        (item) => getText(item).removeDiacritics().toLowerCase(),
        compareNatural,
      );
}
