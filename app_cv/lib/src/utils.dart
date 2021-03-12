import 'package:tekartik_app_cv/src/cv_model.dart';

String logTruncate(String text) {
  var len = 128;
  if (text.length > len) {
    text = text.substring(0, len);
  }
  return text;
}

/// True for null, num, String, bool
bool isBasicTypeOrNull(dynamic value) {
  if (value == null) {
    return true;
  } else if (value is num || value is String || value is bool) {
    return true;
  }
  return false;
}

/// If 2 content are equals
bool cvModelAreEquals(CvModelRead model1, CvModelRead model2) {
  if (model1.fields.length != model2.fields.length) {
    return false;
  }
  for (var CvField in model2.fields) {
    if (model1.field(CvField.name) != CvField) {
      return false;
    }
  }
  return true;
}
