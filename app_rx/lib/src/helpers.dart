import 'package:rxdart/rxdart.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

final _debug = false;

/// Stream helpers
extension TekartikRxStreamExt<T> on Stream<T> {
  /// Convert any stream to a behavior subject
  @Deprecated('Use toBroadcastValueStream')
  BehaviorSubject<T> toBehaviorSubject() {
    StreamSubscription<T>? subscription;
    late BehaviorSubject<T> subject;
    if (_debug) {
      print('toBehaviorSubject $hashCode');
    }
    subject = BehaviorSubject<T>(
      onListen: () {
        if (_debug) {
          print('onListen $hashCode');
        }
        subscription = listen((event) {
          subject.add(event);
        });
      },
      onCancel: () {
        if (_debug) {
          print('onCancel $hashCode');
        }
        subscription?.cancel();
      },
      sync: true,
    );
    return subject;
  }

  /// It won't listen to the stream until the first listener is added and stop
  /// when it is closed.
  BroadcastValueStream<T> toBroadcastValueStream() =>
      _BroadcastValueStream(this);
}

/// Stream subscription is closed when then stream is closed.
abstract class BroadcastValueStream<T> extends ValueStream<T> {
  Future<void> close();
}

class _BroadcastValueStream<T> extends Stream<T>
    implements BroadcastValueStream<T> {
  late final BehaviorSubject<T> _subject;
  StreamSubscription<T>? subscription;

  _BroadcastValueStream(Stream<T> stream) {
    _subject = BehaviorSubject<T>(
      onListen: () {
        if (_debug) {
          print('onListen $hashCode');
        }
        subscription ??= stream.listen((event) {
          _subject.add(event);
        });
      },
      onCancel: () {
        if (_debug) {
          print('onCancel $hashCode');
        }
      },
      sync: true,
    );
  }

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _subject.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  Future<void> close() async {
    if (_debug) {
      print('close $hashCode');
    }
    subscription?.cancel().unawait();
    await _subject.close();
  }

  @override
  bool get isBroadcast => _subject.isBroadcast;

  @override
  Object get error => _subject.error;

  @override
  Object? get errorOrNull => _subject.errorOrNull;

  @override
  bool get hasError => _subject.hasError;

  @override
  bool get hasValue => _subject.hasValue;

  @override
  StackTrace? get stackTrace => _subject.stackTrace;

  @override
  T get value => _subject.value;

  @override
  T? get valueOrNull => _subject.valueOrNull;

  /// Returns the last emitted event (either data/value or error event).
  /// `null` if no value or error events have been emitted yet.
  @override
  StreamNotification<T>? get lastEventOrNull =>
      hasValue
          ? StreamNotification<T>.data(value)
          : hasError
          ? StreamNotification<T>.error(error)
          : null;
}
