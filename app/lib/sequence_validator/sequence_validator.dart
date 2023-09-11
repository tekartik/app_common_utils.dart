/*
package com.tekartik.utils.sequence;

import android.annotation.SuppressLint;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import static java.lang.Boolean.TRUE;

/**
 * Created by alex on 23/05/16.
 * <p>
 * Basic tap pattern recognition
 */
public abstract class SequenceValidator {

    int sequenceIndex = 0;
    private long lastTime = 0;

    static private boolean smallDiff(long diff) {
        return diff <= 500;
    }

    // Ok in Multi, not ok in Suite for small group
    static private boolean mediumDiff(long diff) {
        return diff <= 1000;
    }

    // True if at least 500ms
    static private boolean largeDiff(long diff) {
        return diff >= 500 && diff < 3000;
    }

    protected abstract boolean validate(long timestamp, long diff);

    public boolean validate(long timestamp) {
        long diff = timestamp - lastTime;
        if (diff > 1500) {
            sequenceIndex = 0;
        }

        boolean validated = validate(timestamp, diff);
        lastTime = timestamp;
        return validated;
    }

    @SuppressWarnings("unused")
    public boolean validate() {
        return validate(System.currentTimeMillis());
    }

    static public class Multi extends SequenceValidator {

        static final int DEFAULT_MULTI_COUNT = 6;

        private final int multiCount; // Default multi count

        public Multi() {
            this(DEFAULT_MULTI_COUNT);
        }

        public Multi(int multiCount) {
            this.multiCount = multiCount;
        }

        @Override
        protected boolean validate(long timestamp, long diff) {
            if (sequenceIndex == 0) {
                sequenceIndex = 1;
            } else {
                if (mediumDiff(diff)) {
                    sequenceIndex++;
                } else {
                    sequenceIndex = 1;
                }
            }
            if (sequenceIndex == multiCount) {
                return true;
            }
            return false;
        }


    }

    static public class Suite extends SequenceValidator {

        static final List<Integer> SUITE_LIST_DEFAUT = Arrays.asList(2, 3, 1);
        private final List<Integer> list;
        private final int sequenceCount;
        @SuppressLint("UseSparseArrays")
        private final HashMap<Integer, Boolean> sequenceDiffs = new HashMap<>();


        public Suite() {
            this(SUITE_LIST_DEFAUT);
        }

        public Suite(List<Integer> list) {
            this.list = list;
            int index = 0;
            for (int count : list) {
                // for the first allow any
                index++;
                for (int i = 1; i < count; i++) {
                    // requires small diff then
                    sequenceDiffs.put(index++, true);
                }
            }
            sequenceCount = index;
        }

        @Override
        protected boolean validate(long timestamp, long diff) {
            if (sequenceIndex == 0) {
                sequenceIndex = 1;
            } else {
                Boolean checkSmallDiff = sequenceDiffs.get(sequenceIndex);
                if (TRUE.equals(checkSmallDiff)) {
                    if (SequenceValidator.smallDiff(diff)) {
                        sequenceIndex++;
                    } else {
                        sequenceIndex = 1;
                    }
                } else if (SequenceValidator.largeDiff(diff)) {
                    sequenceIndex++;
                } else {
                    sequenceIndex = 1;
                }
            }
            if (sequenceIndex == sequenceCount) {
                return true;
            }
            return false;
        }
    }

}

 */
import 'dart:async';

/// Helper to validate a simple tick code (morse like)
class SequenceValidator {
  /// the current sequence
  int? _sequenceIndex;

  /// the index in the current sequence
  int? _inSequenceIndex;
  Stopwatch? _stopwatch;
  final List<int>? sequence;
  late int _lastEllapsedMs;
  static const int _smallDiff = 500; // inclusive for small
  static const int _cancelDiff = 1500;
  Completer<bool>? _endValidator;

  SequenceValidator({this.sequence});

  void _cancel() {
    if (_endValidator?.isCompleted == false) {
      _endValidator!.complete(false);
    }
    _endValidator = null;
    _stopwatch = null;
  }

  /// true if currently last in sequence
  bool get _lastInSequence => _inSequenceIndex! >= sequence![_sequenceIndex!];

  bool get _lastSequence => _sequenceIndex! >= sequence!.length - 1;

  late bool _lazyCancelled;

  void restart() {
    _cancel();
  }

  /// timestamp for testing only
  FutureOr<bool> validate([int? timestamp]) {
    if (_stopwatch == null) {
      _lazyCancelled = false;
      _sequenceIndex = 0;
      _inSequenceIndex = 1;
      _lastEllapsedMs = 0;
      _stopwatch = Stopwatch()..start();
    } else {
      var ellapsedMs = timestamp ?? _stopwatch!.elapsedMilliseconds;
      var diff = ellapsedMs - _lastEllapsedMs;
      _lastEllapsedMs = ellapsedMs;

      // this is the only way to cancel: wait for 1500ms
      if (diff > _cancelDiff) {
        _cancel();
        return validate(ellapsedMs);
      }
      // We were at the end...too bad
      if (_endValidator != null) {
        _endValidator?.complete(false);
        _endValidator = null;
        _lazyCancelled = true;
      }

      if (_lazyCancelled) {
        // should wait!
        return false;
      }

      // What do we expect?

      // We are not the first expect a short delay
      if (_inSequenceIndex! > 0) {
        // Expect a short delay
        if (diff > _smallDiff) {
          _lazyCancelled = true;
          return false;
        }
      } else if (_sequenceIndex! > 0) {
        // first item of any group but the first one
        if (_inSequenceIndex == 0) {
          // expect a long delay
          if (diff <= _smallDiff) {
            _lazyCancelled = true;
            return false;
          }
        }
      }
      _inSequenceIndex = _inSequenceIndex! + 1;
    }
    if (_lastInSequence) {
      if (_lastSequence) {
        var completer = _endValidator = Completer<bool>();
        Future<void>.delayed(const Duration(milliseconds: _smallDiff))
            .then((_) {
          if (completer.isCompleted) {
            completer.complete(true);
          }
        });
        return completer.future;
      } else {
        _sequenceIndex = _sequenceIndex! + 1;
        _inSequenceIndex = 0;
      }
    }
    return false;
    // Are we done
  } // inclusive for large
}
