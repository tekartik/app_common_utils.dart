import 'dart:typed_data';

import 'package:cv/cv.dart';
import 'package:sembast/blob.dart';
import 'package:sembast/timestamp.dart';

/// Never change this def or behavior
CvFillOptions get cvSembastFillOptions1 => CvFillOptions(
  valueStart: 0,
  collectionSize: 1,
  generate: (type, options) {
    if (options.valueStart != null) {
      if (type == Timestamp) {
        var value = options.valueStart = options.valueStart! + 1;
        return Timestamp(value, 0);
      } else if (type == Model || type == Map) {
        var value = options.valueStart = options.valueStart! + 1;
        return <String, Object?>{'value': value};
      } else if (type == Blob) {
        var value = options.valueStart = options.valueStart! + 1;
        return Blob(
          Uint8List.fromList(List<int>.generate(value, (index) => index % 256)),
        );
      }
    }
    return null;
  },
);
