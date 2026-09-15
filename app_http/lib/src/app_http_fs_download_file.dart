import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/utils/read_write.dart';
import 'package:http/http.dart' show ClientException, Request;
import 'package:tekartik_app_http/app_http.dart';

/// File system extension on [Client].
extension HttpClientFsExt on Client {
  /// Download a file to [file].
  ///
  /// The response body is streamed to [file] (using `streamToFile` from
  /// `package:fs_shim/utils/read_write.dart`), the parent directory is
  /// created if missing.
  ///
  /// Does not download if it already exists, unless [force] is true.
  ///
  /// Throws a [ClientException] if the request fails; no partial file is left
  /// behind in that case.
  Future<void> fsDownloadFile(Uri url, File file, {bool? force}) async {
    force ??= false;
    if (!force) {
      if (await file.exists()) {
        // Already present
        return;
      }
    }
    var response = await send(Request('GET', url));
    if (!isHttpStatusCodeSuccessful(response.statusCode)) {
      // Consume the body before reporting the error
      try {
        await response.stream.drain<void>();
      } catch (_) {
        // ignore
      }
      var message = 'Request to $url failed with status ${response.statusCode}';
      var reasonPhrase = response.reasonPhrase;
      if (reasonPhrase != null) {
        message = '$message: $reasonPhrase';
      }
      throw ClientException('$message.', url);
    }
    try {
      await streamToFile(response.stream, file);
    } catch (_) {
      // Don't leave a partial file behind
      try {
        await file.delete();
      } catch (_) {
        // ignore
      }
      rethrow;
    }
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
