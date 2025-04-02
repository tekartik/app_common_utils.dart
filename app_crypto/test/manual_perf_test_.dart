import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_common_utils/num_utils.dart';
import 'package:test/test.dart';

class _TestEncrypter {
  final String name;
  final StringEncrypter encrypter;
  _TestEncrypter(this.name, this.encrypter);
}

class _TestAction {
  final String name;
  final void Function() action;
  _TestAction(this.name, this.action);
}

String textWithLength(int length) {
  return List.generate(length, (i) => i.toString().substring(0, 1)).join();
}

void main() {
  var password = encryptTextPassword16FromText('password');
  var testEncrypters = [
    _TestEncrypter('aes', aesEncrypterFromPassword(password)),
    _TestEncrypter('salsa20', salsa20EncrypterFromPassword(password)),
  ];

  group('perf', () {
    for (var testEncrypter in testEncrypters) {
      var name = testEncrypter.name;
      test(name, () {
        var encrypter = testEncrypter.encrypter;
        for (var data in [
          textWithLength(10),
          textWithLength(1000),
          textWithLength(10000),
        ]) {
          var encryptedData = encrypter.encrypt(data);
          expect(encrypter.decrypt(encryptedData), data);

          var initialEstimationSize = 10;

          int actionsDurationMs(int count, void Function() action) {
            var sw = Stopwatch()..start();
            for (var i = 0; i < count; i++) {
              action();
            }
            sw.stop();
            return sw.elapsedMilliseconds;
          }

          void execute(_TestAction testAction) {
            void action() {
              testAction.action();
            }

            var count = initialEstimationSize;
            int ms;
            while (true) {
              ms = actionsDurationMs(count, action);
              // print('count: $count ms: $ms');
              if (ms < 50) {
                count = (count * 1.2).toInt();
              } else {
                break;
              }
            }
            var countPerMs = count / ms;
            var durationTestMs = 500;
            var countTest = (countPerMs * durationTestMs).toInt();

            // print('countTest: $countTest (${(countPerMs * 1000).toInt()} per/s)');
            for (var i = 0; i < 1; i++) {
              encryptedData = encrypter.encrypt(data);

              var msTest = actionsDurationMs(countTest, action).boundedMin(1);
              countPerMs = countTest / msTest;
              print(
                '$name ${data.length} ${testAction.name}: (${(countPerMs * 1000).toInt()} per/s)',
              );
            }
          }

          execute(
            _TestAction('encrypt', () {
              encrypter.encrypt(data);
            }),
          );
          execute(
            _TestAction('decrypt', () {
              encrypter.decrypt(encryptedData);
            }),
          );
        }
      });
    }
  });
}
