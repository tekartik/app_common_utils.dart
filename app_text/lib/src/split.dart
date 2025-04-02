/// Splits a string by any sequence of one or more whitespace characters (\s+).
///
/// It first trims the input string to remove leading/trailing whitespace.
/// If the trimmed string is empty (i.e., the original was empty or only contained whitespace),
/// an empty list is returned. Otherwise, the trimmed string is split.
///
/// Args:
///   inputString: The string to split.
///
/// Returns:
///   A list of non-empty strings resulting from the split, or an empty list.
List<String> stringSplitByWhitespace(String inputString) {
  // Trim leading and trailing whitespace.
  final trimmedString = inputString.trim();

  // If the string is empty after trimming, return an empty list.
  if (trimmedString.isEmpty) {
    return [];
  }

  // Split the trimmed string using the regex.
  return trimmedString.split(_whitespaceRegex);
}

// Define the regex for one or more whitespace characters.
final _whitespaceRegex = RegExp(r'\s+');
