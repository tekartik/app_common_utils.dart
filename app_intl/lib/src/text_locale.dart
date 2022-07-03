const enLanguageName = 'en';
const frLanguageName = 'fr';

const usCountryCode = 'US';
const frCountryCode = 'FR';

const enUsLocaleName = '${enLanguageName}_$usCountryCode';
const frFrLocaleName = '${frLanguageName}_$frCountryCode';

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
