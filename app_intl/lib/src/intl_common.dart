import 'dart:convert';

String intlSafeKey(String key) {
  var paramIndex = key.indexOf('{{');
  if (paramIndex != -1) {
    if (key.substring(paramIndex + 2).contains('}}')) {
      return key.substring(0, paramIndex);
    }
  }
  return key;
}

Map<String, String> intlSafeLocalizationMap(Map map) {
  var newMap = <String, String>{};
  for (var entry in map.entries) {
    newMap[intlSafeKey(entry.key as String)] = entry.value as String;
  }
  return newMap;
}

/// Localization map must be a safe localization map
String intlText(
  Map<String, String> localizationMap,
  String key, {
  Map<String, String?>? data,
  Map<String, String>? defaultLocalizationMap,
}) {
  var text = localizationMap[key] ?? defaultLocalizationMap?[key] ?? '[$key]';

  return intlRender(text, data: data);
}

String intlRender(String template, {Map<String, String?>? data}) {
  var text = template;
  data?.forEach((key, value) {
    text = text.replaceAll('{{$key}}', value!);
  });
  return text;
}

/// Load localization map from an asset
Map<String, String> intlDecodeLocalizationMap(String json) {
  var src = jsonDecode(json) as Map;
  return intlSafeLocalizationMap(src);
}
