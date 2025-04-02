import 'sanitized_text.dart';

/// Finder helper
abstract class SearchTextFinder {
  /// The search text
  String get searchText;

  /// Factory constructor
  factory SearchTextFinder({required String searchText}) =>
      _SearchTextFinder(searchText: searchText);

  /// Find in text
  bool findIn(String text);
}

class _SearchTextFinder implements SearchTextFinder {
  @override
  final String searchText;
  late final sanitizedText = sanitizeText(searchText);
  late final searchWords = sanitizedText.sanitizedWords;
  _SearchTextFinder({required this.searchText});

  @override
  bool findIn(String text) {
    var content = sanitizeText(text);
    var contentWords = content.sanitizedWords;
    for (var searchWord in searchWords) {
      for (var contentWord in contentWords) {
        if (contentWord.toLowerCase().contains(searchWord)) {
          return true;
        }
      }
    }
    return false;
  }
}
