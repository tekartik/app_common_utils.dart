// To deprecate
const enLanguageName = englishLanguageCode;
// To deprecate
const frLanguageName = frenchLanguageCode;

const englishLanguageCode = 'en';
const frenchLanguageCode = 'fr';

// To deprecate
const usCountryCode = usaCountryCode;
// To deprecate
const frCountryCode = franceCountryCode;

const usaCountryCode = 'US';
const franceCountryCode = 'FR';
const enUsLocaleName = '${englishLanguageCode}_$usaCountryCode';
const frFrLocaleName = '${frenchLanguageCode}_$franceCountryCode';

class TextLocale {
  final String name;

  const TextLocale(this.name);

  @override
  String toString() => 'TL($name)';

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is TextLocale) {
      return name == other.name;
    }
    return false;
  }
}

const enUsTextLocale = TextLocale(enUsLocaleName);
const frFrTextLocale = TextLocale(frFrLocaleName);
