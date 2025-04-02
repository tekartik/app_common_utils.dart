import 'package:cv/cv.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Helper on maps
extension AppCvFirestoreFieldMapExt on Model {
  /// User a server timestamp
  void withServerTimestamp(CvField<Timestamp> field) =>
      cvOverride(field, FieldValue.serverTimestamp);

  /// User a server timestamp
  void withDelete(CvField field) => cvOverride(field, FieldValue.delete);
}

/// Helper with server timestamp
mixin WithServerTimestampMixin implements CvModel {
  final timestamp = CvField<Timestamp>('timestamp');

  List<CvField> get timedMixinFields => [timestamp];

  Model toMapWithServerTimestamp({
    List<String>? columns,
    bool includeMissingValue = false,
  }) =>
      toMap(columns: columns, includeMissingValue: includeMissingValue)
        ..withServerTimestamp(timestamp);
}
