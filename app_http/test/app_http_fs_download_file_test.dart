import 'package:tekartik_app_http/app_http.dart';
import 'package:tekartik_app_http/app_http_fs_download_file.dart';
import 'package:tekartik_common_utils/async_utils.dart';
import 'package:test/test.dart';

var simplePublicUrl = 'https://cdn.ampproject.org/v0.js';

void main() {
  var fs = fileSystemDefault;
  var file = fs.sandbox().file(fs.path.join('.local', 'downloaded_file.js'));
  group('app_http_fs_download_file', () {
    test('download', () async {
      await httpClientFactoryUniversal.fsDownloadFile(
        Uri.parse(simplePublicUrl),
        file,
      );
      var stat = await file.stat();
      var updated = stat.modified;
      await sleep(1000);
      await httpClientFactoryUniversal.fsDownloadFile(
        Uri.parse(simplePublicUrl),
        file,
      );
      stat = await file.stat();
      expect(stat.modified, updated);
      await httpClientFactoryUniversal.fsDownloadFile(
        Uri.parse(simplePublicUrl),
        file,
        force: true,
      );
      stat = await file.stat();
      expect(stat.modified, isNot(updated));
    });
  });
}
