import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// Stream helpers
extension TekartikRxStreamExt<T> on Stream<T> {
  /// Convert any stream to a behavior subject
  BehaviorSubject<T> toBehaviorSubject() {
    late StreamSubscription<T> subscription;
    late BehaviorSubject<T> subject;
    subject = BehaviorSubject<T>(onListen: () {
      subscription = listen((event) {
        subject.add(event);
      });
    }, onCancel: () {
      subscription.cancel();
    });
    return subject;
  }
}
