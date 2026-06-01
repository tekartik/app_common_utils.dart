import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_app_http/app_http.dart';

/// File system extension on [Client].
extension HttpClientFsExt on Client {
  /// Download a file to [file].
  ///
  /// Does not download if it already exists, unless [force] is true.
  Future<void> fsDownloadFile(Uri url, File file, {bool? force}) async {
    force ??= false;
    if (!force) {
      if (await file.exists()) {
        // Already present
        return;
      }
    }
    await file.parent.create(recursive: true);
    var bytes = await readBytes(url);
    await file.writeAsBytes(bytes);
  }
}

/// Http client factory io helpers
extension HttpClientFactoryFsExt on HttpClientFactory {
  /// Download a file to [file]
  /// Does not download if it already exists, unless [force] is true

  Future<void> fsDownloadFile(Uri url, File file, {bool? force}) async {
    var client = newClient();
    try {
      await client.fsDownloadFile(url, file, force: force);
    } finally {
      client.close();
    }
  }
}

/// Download a file to [file] using the universal client factory.
///
/// Does not download if it already exists, unless [force] is true.
Future<void> httpFsDownloadFile(Uri url, File file, {bool? force}) async {
  await httpClientFactoryUniversal.fsDownloadFile(url, file, force: force);
}
