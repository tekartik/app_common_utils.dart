import 'dart:convert';

import 'package:tekartik_app_pb/pb.dart';
import 'package:test/test.dart';

import 'src/test_data.dart';

/// Field numbers of `google.testing.platform.proto.api.core.TestSuiteResult`
/// (an android instrumented test run result), as the matching
/// `test/data/test-result.textproto` tells them.
const suiteMetaDataField = 1;
const suiteStatusField = 2;
const suiteResultField = 3;
const suiteArtifactField = 5;
const metaScheduledCountField = 2;
const metaDeviceField = 3;
const resultTestCaseField = 1;
const resultStatusField = 2;
const resultArtifactField = 4;
const testCaseClassField = 1;
const testCasePackageField = 2;
const testCaseMethodField = 3;
const testCaseStartTimeField = 6;
const timestampSecondsField = 1;
const timestampNanosField = 2;
const artifactLabelField = 1;
const artifactSourcePathField = 2;

/// PASSED in the TestStatus enum.
const statusPassed = 3;

void main() {
  var testResultBytes = base64.decode(testResultPbBase64);
  var deviceInfoBytes = base64.decode(deviceInfoPbBase64);

  test('test result', () {
    var result = pbDecodeMessage(testResultBytes);
    expect(result.numbers, [
      suiteMetaDataField,
      suiteStatusField,
      suiteResultField,
      suiteArtifactField,
    ]);
    expect(result.intValue(suiteStatusField), statusPassed);

    var meta = result.messageValue(suiteMetaDataField)!;
    expect(meta.intValue(metaScheduledCountField), 9);
    expect(meta.messageValue(metaDeviceField)!.stringValue(1), 'emulator-5554');

    var results = result.messageValues(suiteResultField);
    expect(results, hasLength(9));
    var names = [
      for (var testResult in results)
        () {
          var testCase = testResult.messageValue(resultTestCaseField)!;
          return '${testCase.stringValue(testCaseClassField)}.'
              '${testCase.stringValue(testCaseMethodField)}';
        }(),
    ];
    expect(names.first, 'LocaleUtilsTest.localeForLanguateTag');
    expect(names, contains('TestSqflitePluginTest.walEnabled'));
    for (var testResult in results) {
      expect(testResult.intValue(resultStatusField), statusPassed);
      var testCase = testResult.messageValue(resultTestCaseField)!;
      expect(
        testCase.stringValue(testCasePackageField),
        'com.tekartik.sqflite',
      );
    }

    var first = results.first.messageValue(resultTestCaseField)!;
    var start = first.messageValue(testCaseStartTimeField)!;
    expect(start.intValue(timestampSecondsField), 1792583865);
    expect(start.intValue(timestampNanosField), 834000000);

    var artifact = results.first.messageValues(resultArtifactField).first;
    expect(artifact.messageValue(artifactLabelField)!.stringValue(1), 'logcat');
    expect(
      artifact.messageValue(artifactSourcePathField)!.stringValue(1),
      endsWith(
        'logcat-com.tekartik.sqflite.LocaleUtilsTest-localeForLanguateTag.txt',
      ),
    );
  });

  test('suite artifact', () {
    var result = pbDecodeMessage(testResultBytes);
    var artifact = result.messageValue(suiteArtifactField)!;
    expect(
      artifact.messageValue(artifactLabelField)!.stringValue(1),
      'test-results.log',
    );
    // type: TEST_DATA, mime_type: "text/plain".
    expect(artifact.intValue(4), 3);
    expect(artifact.stringValue(6), 'text/plain');
  });

  test('test result round trip', () {
    expect(pbEncodeMessage(pbDecodeMessage(testResultBytes)), testResultBytes);
  });

  test('test result as text', () {
    var text = pbMessageToText(pbDecodeMessage(testResultBytes));
    var lines = const LineSplitter().convert(text);
    expect(lines.take(8), [
      '1 {',
      '  2: 9',
      '  3 {',
      '    1: "emulator-5554"',
      '    2: "primary"',
      '  }',
      '}',
      '2: 3',
    ]);
    expect(lines.where((line) => line == '3 {'), hasLength(9));
  });

  test('device info', () {
    var info = pbDecodeMessage(deviceInfoBytes);
    expect(info.stringValue(1), 'Pixel_9a_like');
    expect(info.stringValue(2), '36');
    expect(info.intValue(3), 2531824000);
    expect(info.stringValues(5), ['x86_64', 'arm64-v8a']);
    expect(pbEncodeMessage(info), deviceInfoBytes);
    expect(pbMessageToText(info), '''
1: "Pixel_9a_like"
2: "36"
3: 2531824000
4: "Android virtual processor"
5: "x86_64"
5: "arm64-v8a"
6: "Google"
7: "emulator-5554"
8: "Pixel_9a_like"
10: "sdk_gphone64_x86_64"
''');
  });
}
