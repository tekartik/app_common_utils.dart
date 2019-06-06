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

import 'package:tekartik_app_common_utils/sequence_validator/sequence_validator.dart';
import 'package:test/test.dart';

void main() {
  group('sequence_validator', () {
    test('1', () async {
      var vtor = SequenceValidator(sequence: <int>[1]);
      var result = vtor.validate();
      expect(result, const TypeMatcher<Future>());
      expect(await result, true);

      // Press once more
      vtor.restart();
      result = vtor.validate();
      expect(result, const TypeMatcher<Future>());
      expect(vtor.validate(), false);
      expect(await result, false);
    });

    test('2', () async {
      var vtor = SequenceValidator(sequence: <int>[2]);
      expect(vtor.validate(0), false);
      var result = vtor.validate(0);
      expect(result, const TypeMatcher<Future>());
      expect(await result, true);
    });

    test('cancelled', () async {
      var vtor = SequenceValidator(sequence: <int>[2]);
      expect(vtor.validate(0), false);
      var result = vtor.validate(0);
      expect(result, const TypeMatcher<Future>());

      expect(vtor.validate(0), isFalse);
      expect(await result, isFalse);
    });

    test('2 groups success', () async {
      var vtor = SequenceValidator(sequence: <int>[1, 1]);
      expect(vtor.validate(0), isFalse);
      expect(await vtor.validate(501), isTrue);
    });

    test('2 groups failure', () async {
      var vtor = SequenceValidator(sequence: <int>[1, 1]);
      expect(vtor.validate(0), isFalse);
      expect(vtor.validate(0), isFalse);

      vtor = SequenceValidator(sequence: <int>[1, 1]);
      expect(vtor.validate(0), isFalse);
      expect(vtor.validate(500), isFalse);

      vtor = SequenceValidator(sequence: <int>[1, 1]);
      expect(vtor.validate(0), isFalse);
      var result = vtor.validate(501);
      expect(result, const TypeMatcher<Future>());

      expect(vtor.validate(500), isFalse);
      expect(await result, isFalse);
      /*
      var result = vtor.validate();
      expect(result, const TypeMatcher<Future>());
      expect(await result, true);

      // Press once more
      vtor.restart();
      result = vtor.validate();
      expect(result, const TypeMatcher<Future>());
      expect(vtor.validate(), false);
      expect(await result, false);

       */
    });

    test('2x2 groups success', () async {
      var vtor = SequenceValidator(sequence: <int>[2, 2]);
      expect(vtor.validate(0), isFalse);
      expect(vtor.validate(0), isFalse);
      expect(vtor.validate(501), isFalse);
      expect(await vtor.validate(501), isTrue);
    });
  });
}
