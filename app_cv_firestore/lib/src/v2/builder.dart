import 'package:cv/cv.dart';
// ignore: implementation_imports

/// Add builder
void cvFirestoreAddBuilder<T extends CvModel>(
  T Function(Map contextData) builder,
) {
  cvAddBuilder(builder);
}
