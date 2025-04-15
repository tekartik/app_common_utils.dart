import 'sanitized_text.dart';

/// Finder helper
abstract class SearchTextFinder {
  /// The search text
  String get searchText;

  /// Factory constructor
  factory SearchTextFinder({required String searchText}) =>
      _SearchTextFinder(searchText: searchText);

  /// Find any in text
  bool findIn(String text);

  /// Find all in text
  bool findAllIn(String text);
}

class _SearchTextFinder implements SearchTextFinder {
  @override
  final String searchText;
  late final sanitizedSearchText = sanitizeText(searchText);
  String get sanitizeSearchString => sanitizedSearchText.sanitizedString;
  late final searchWords = sanitizedSearchText.sanitizedWords;
  _SearchTextFinder({required this.searchText});

  @override
  bool findIn(String text) {
    var content = sanitizeText(text);
    var contentWords = content.sanitizedWords;
    for (var searchWord in searchWords) {
      var found = false;
      for (var contentWord in contentWords) {
        if (contentWord.contains(searchWord)) {
          found = true;
          break;
        }
      }
      if (!found) {
        return false;
      }
    }
    return true;
  }

  @override
  bool findAllIn(String text) {
    return sanitizeString(text).contains(sanitizeSearchString);
  }
}
