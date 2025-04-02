import 'package:diacritic/diacritic.dart';

/// SanitizedText class
class SanitizedText implements Comparable<SanitizedText> {
  /// Original text
  final String text;

  /// Sanitized string
  final String sanitizedString;

  /// Constructor
  SanitizedText({required this.text, required this.sanitizedString});

  @override
  int compareTo(SanitizedText other) {
    return sanitizedString.compareTo(other.sanitizedString);
  }

  @override
  int get hashCode => sanitizedString.hashCode;

  @override
  String toString() => text;

  @override
  bool operator ==(Object other) {
    if (other is! SanitizedText) return false;
    return text == other.text;
  }
}

/// Extension for String to get sanitized text
extension SanitizedTextExt on SanitizedText {
  /// Search words (split by whitespace)
  List<String> get sanitizedWords => sanitizedString.split('_');
}

/// Helper for generating a convenient sanitized string
String sanitizeString(String text) {
  text = text.trim();
  text = removeDiacritics(text);
  text = replaceNonAlphaNumericWithSingle(text, replace: '_');
  if (text.startsWith('_')) {
    if (text.endsWith('_')) {
      text = text.substring(1, text.length - 1);
    } else {
      text = text.substring(1);
    }
  } else if (text.endsWith('_')) {
    text = text.substring(0, text.length - 1);
  }
  text = text.toLowerCase();
  return text;
}

/// Helper for generating a convenient SanitizedText
/// trimming, remove diacritics, and converting to lower case
SanitizedText sanitizeText(String text) {
  var sanitizedString = sanitizeString(text);
  return SanitizedText(text: text, sanitizedString: sanitizedString);
}

/// Replaces any sequence of one or more non-alphanumeric characters
/// in the input string with a single space.
///
/// Non-alphanumeric characters are anything outside the ranges a-z, A-Z, and 0-9.
///
/// Args:
///   inputString: The string to process.
///
/// Returns:
///   A new string where sequences of non-alphanumeric characters are replaced by a single space.
///   Note: This might result in leading or trailing spaces if the original string
///   started or ended with non-alphanumeric characters. Use `.trim()` on the result
///   if you want to remove those.
String replaceNonAlphaNumericWithSingle(
  String inputString, {
  String replace = ' ',
}) {
  // Regex to match one or more (+) non-alphanumeric characters ([^a-zA-Z0-9]).
  // Spaces are considered non-alphanumeric by this regex.
  final nonAlphaNumericSequenceRegex = RegExp(r'[^a-zA-Z0-9]+');

  // Replace all matches of the regex with a single space ' '.
  return inputString.replaceAll(nonAlphaNumericSequenceRegex, replace);
}
