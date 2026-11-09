// ignore_for_file: avoid_print

import 'package:tekartik_app_intl/intl.dart';

/// As written by the generator (`LocalizationProject.intlGenerateFile`) in
/// `lib/src/text/localization_gen.dart`, from `assets/i18n/en_US.json`.
mixin AppLocalizationsMixinGen {
  String get hello => t('hello');
  String score({required String points, required String total}) =>
      t('score', {'points': points, 'total': total});
  String t(String key, [Map<String, String>? data]);
}

/// The app side: the texts of a locale, English as fallback.
class AppLocalizations with AppLocalizationsMixinGen {
  final TextLocale locale;
  final Map<String, String> localizationMap;
  final Map<String, String> defaultLocalizationMap;

  AppLocalizations(
    this.locale,
    this.localizationMap, {
    required this.defaultLocalizationMap,
  });

  @override
  String t(String key, [Map<String, String>? data]) => intlText(
    localizationMap,
    key,
    data: data,
    defaultLocalizationMap: defaultLocalizationMap,
  );
}

/// The content of assets/i18n/en_US.json and fr_FR.json (read with
/// `rootBundle`, `File`, http...).
const enUsJson = '''
{
  "hello": "Hello",
  "score{{points, total}}": "{{points}} out of {{total}}"
}
''';
const frFrJson = '''
{
  "score{{points, total}}": "{{points}} sur {{total}}"
}
''';

void main() {
  var enUs = intlDecodeLocalizationMap(enUsJson);
  var frFr = intlDecodeLocalizationMap(frFrJson);
  for (var (locale, map) in [(enUsTextLocale, enUs), (frFrTextLocale, frFr)]) {
    var texts = AppLocalizations(locale, map, defaultLocalizationMap: enUs);
    // fr_FR has no "hello": the English text is used.
    print(
      '${locale.name}: ${texts.hello}, ${texts.score(points: '3', total: '10')}',
    );
  }
  // en_US: Hello, 3 out of 10
  // fr_FR: Hello, 3 sur 10
}
