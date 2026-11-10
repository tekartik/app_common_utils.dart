import 'package:http/http.dart' show ClientException;
import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_http/app_http_fs_download_file.dart';
import 'package:tekartik_common_utils/async_utils.dart';
import 'package:test/test.dart';

import 'app_http_test.dart' show connectedFixtureUri;

void main() {
  group('app_http_fs_download_file', () {
    test('download', () async {
      var fs = fileSystemDefault;
      var file = fs.sandbox().file(fs.path.join('.local', 'connected.json'));
      if (await file.exists()) {
        await file.delete();
      }
      await httpClientFactoryUniversal.fsDownloadFile(
        connectedFixtureUri,
        file,
      );
      expect(await file.readAsString(), contains('tekartik_http_test'));
      var stat = await file.stat();
      var updated = stat.modified;
      await sleep(1000);
      // Already there: not downloaded again.
      await httpClientFactoryUniversal.fsDownloadFile(
        connectedFixtureUri,
        file,
      );
      stat = await file.stat();
      expect(stat.modified, updated);
      await httpClientFactoryUniversal.fsDownloadFile(
        connectedFixtureUri,
        file,
        force: true,
      );
      stat = await file.stat();
      expect(stat.modified, isNot(updated));
    });

    // No network: the memory client and server.
    test('error status', () async {
      var server = await httpServerFactoryMemory.bind(localhost, portDynamic);
      server.listen((request) async {
        request.response.statusCode = httpStatusCodeNotFound;
        await request.response.close();
      });
      var fs = fileSystemMemory;
      var file = fs.file(fs.path.join('app_http_test', 'missing.txt'));
      try {
        await expectLater(
          httpClientFactoryMemory.fsDownloadFile(
            httpServerGetUri(server).resolve('missing.txt'),
            file,
          ),
          throwsA(isA<ClientException>()),
        );
        expect(await file.exists(), isFalse);
      } finally {
        await server.close();
      }
    });
  });
}
