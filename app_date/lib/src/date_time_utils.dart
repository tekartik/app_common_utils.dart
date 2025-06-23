extension TekartikAppDateTimeUtils on DateTime {
  /// Good for filename
  /// example 20231231T235959
  String sanitizeToSeconds() {
    return '${year.toString().padLeft(4, '0')}${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}T'
        '${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}${second.toString().padLeft(2, '0')}';
  }
}
