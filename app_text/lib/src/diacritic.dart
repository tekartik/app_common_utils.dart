import 'package:diacritic/diacritic.dart' as diacritic;

/// Remove diacritics from a string
extension TekartikAppTextDiacriticsExt on String {
  /// Remove diacritics from a string
  String removeDiacritics() {
    return diacritic.removeDiacritics(this);
  }
}
