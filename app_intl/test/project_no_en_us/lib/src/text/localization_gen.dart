mixin AppLocalizationsMixinGen {
  String zzTest2Params({required String p1, required String p2}) =>
      t('zzTest2Params', {'p1': p1, 'p2': p2});
  String zzTestCount({required String count}) =>
      t('zzTestCount', {'count': count});
  String get zzYy => t('zz_yy');
  String get zzzTestLast => t('zzzTestLast');
  String t(String key, [Map<String, String>? data]);
}
