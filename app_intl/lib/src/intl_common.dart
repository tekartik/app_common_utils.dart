import 'dart:convert';

/// The lookup key of a JSON key: without its `{{...}}` parameter suffix
/// (`welcome{{name}}` gives `welcome`).
String intlSafeKey(String key) {
  var paramIndex = key.indexOf('{{');
  if (paramIndex != -1) {
    if (key.substring(paramIndex + 2).contains('}}')) {
      return key.substring(0, paramIndex);
    }
  }
  return key;
}

/// A decoded JSON localization [map] with its keys passed to [intlSafeKey],
/// as [intlText] expects.
Map<String, String> intlSafeLocalizationMap(Map map) {
  var newMap = <String, String>{};
  for (var entry in map.entries) {
    newMap[intlSafeKey(entry.key as String)] = entry.value as String;
  }
  return newMap;
}

/// The text of [key] rendered with [data] (see [intlRender]), from
/// [localizationMap], else from [defaultLocalizationMap], else `[key]`.
///
/// Localization maps must be safe localization maps
/// ([intlSafeLocalizationMap]).
String intlText(
  Map<String, String> localizationMap,
  String key, {
  Map<String, String?>? data,
  Map<String, String>? defaultLocalizationMap,
}) {
  var text = localizationMap[key] ?? defaultLocalizationMap?[key] ?? '[$key]';

  return intlRender(text, data: data);
}

/// [template] with each `{{name}}` replaced by `data[name]`.
///
/// A null value in [data] throws, even for a name absent from [template].
String intlRender(String template, {Map<String, String?>? data}) {
  var text = template;
  data?.forEach((key, value) {
    text = text.replaceAll('{{$key}}', value!);
  });
  return text;
}

/// Decodes a JSON localization map (the content of an
/// `assets/i18n/<locale>.json` file) as a safe localization map.
Map<String, String> intlDecodeLocalizationMap(String json) {
  var src = jsonDecode(json) as Map;
  return intlSafeLocalizationMap(src);
}
