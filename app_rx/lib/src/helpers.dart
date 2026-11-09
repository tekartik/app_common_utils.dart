import 'package:rxdart/rxdart.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

final _debug = false;
void _log(Object? message) {
  // ignore: avoid_print
  print(message);
}

/// Stream helpers
extension TekartikRxStreamExt<T> on Stream<T> {
  /// Convert any stream to a behavior subject
  @Deprecated('Use toBroadcastValueStream')
  BehaviorSubject<T> toBehaviorSubject() {
    StreamSubscription<T>? subscription;
    late BehaviorSubject<T> subject;
    if (_debug) {
      _log('toBehaviorSubject $hashCode');
    }
    subject = BehaviorSubject<T>(
      onListen: () {
        if (_debug) {
          _log('onListen $hashCode');
        }
        subscription = listen((event) {
          subject.add(event);
        });
      },
      onCancel: () {
        if (_debug) {
          _log('onCancel $hashCode');
        }
        subscription?.cancel();
      },
      sync: true,
    );
    return subject;
  }

  /// A broadcast stream replaying the last value (a sync `BehaviorSubject`).
  ///
  /// It won't listen to the stream until the first listener is added and
  /// stops when it is closed (not when the listeners cancel): call
  /// [BroadcastValueStream.close].
  BroadcastValueStream<T> toBroadcastValueStream() =>
      _BroadcastValueStream(this);

  /// A broadcast stream without replay (a sync `PublishSubject`).
  ///
  /// Same life cycle as [toBroadcastValueStream]: call
  /// [BroadcastStream.close].
  BroadcastStream<T> toBroadcastStream() => _BroadcastStream<T>(this);
}

/// Stream subscription is closed when then stream is closed.
abstract class BroadcastStream<T> extends Stream<T> {
  /// Cancels the source subscription and closes the stream.
  Future<void> close();
}

/// Common implementation: [_subject] listens to the source stream on its
/// first listener and forwards its data, errors and done.
abstract class _SubjectBroadcastStream<T> extends Stream<T> {
  Subject<T> get _subject;
  StreamSubscription<T>? _subscription;

  void _onListen(Stream<T> stream) {
    if (_debug) {
      _log('onListen $hashCode');
    }
    _subscription ??= stream.listen(
      _subject.add,
      onError: _subject.addError,
      onDone: () {
        _subject.close().unawait();
      },
    );
  }

  void _onCancel() {
    if (_debug) {
      _log('onCancel $hashCode');
    }
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

  Future<void> close() async {
    if (_debug) {
      _log('close $hashCode');
    }
    _subscription?.cancel().unawait();
    await _subject.close();
  }

  @override
  bool get isBroadcast => _subject.isBroadcast;
}

class _BroadcastStream<T> extends _SubjectBroadcastStream<T>
    implements BroadcastStream<T> {
  @override
  late final PublishSubject<T> _subject;
  _BroadcastStream(Stream<T> stream) {
    _subject = PublishSubject<T>(
      onListen: () => _onListen(stream),
      onCancel: _onCancel,
      sync: true,
    );
  }
}

/// Stream subscription is closed when then stream is closed.
abstract class BroadcastValueStream<T> extends ValueStream<T> {
  /// Cancels the source subscription and closes the stream.
  Future<void> close();
}

class _BroadcastValueStream<T> extends _SubjectBroadcastStream<T>
    implements BroadcastValueStream<T> {
  @override
  late final BehaviorSubject<T> _subject;

  _BroadcastValueStream(Stream<T> stream) {
    _subject = BehaviorSubject<T>(
      onListen: () => _onListen(stream),
      onCancel: _onCancel,
      sync: true,
    );
  }

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

  /// Returns the last emitted event (either data/value or error event, with
  /// its stack trace), as the [BehaviorSubject] does.
  /// `null` if no value or error events have been emitted yet.
  @override
  StreamNotification<T>? get lastEventOrNull => _subject.lastEventOrNull;
}
