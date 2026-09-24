import 'package:path/path.dart' as p;

/// Default mapping of an url to a relative posix path in the output
/// directory: `<host>/<path>`.
///
/// * The host is followed by `_<port>` when the url has an explicit port
///   (`localhost_8080`).
/// * A path ending with `/` (or empty) gets `index.html`.
/// * A query is appended to the file name before its extension
///   (`css2?family=Roboto` gives `css2_family=Roboto`, `app.js?v=2` gives
///   `app_v=2.js`).
/// * Characters invalid on common file systems (`<>:"\|?*`) are replaced by
///   `_` and very long names are shortened with a hash suffix.
///
/// Html contents whose path does not end with `.html` or `.htm` get `.html`
/// appended when saved, see [webScrapperHtmlLocalPath].
String webScrapperDefaultLocalPath(Uri uri) {
  var host = _sanitize(uri.host);
  if (uri.hasPort) {
    host = '${host}_${uri.port}';
  }
  final segments = uri.pathSegments.map(_sanitize).toList();
  if (segments.isEmpty || uri.path.endsWith('/')) {
    if (segments.isNotEmpty) {
      // Last segment is empty
      segments.removeLast();
    }
    segments.add('index.html');
  }
  if (uri.hasQuery && uri.query.isNotEmpty) {
    final last = segments.removeLast();
    final extension = p.url.extension(last);
    final name = last.substring(0, last.length - extension.length);
    segments.add('${name}_${_sanitizeQuery(uri.query)}$extension');
  }
  return p.url.joinAll([host, ...segments.map(_shorten)]);
}

/// Returns [path] with `.html` appended unless it already ends with `.html`
/// or `.htm` (case insensitive), so that pages like `/about` or
/// `/page.php?id=1` are saved as `about.html` and `page_id=1.php.html` and
/// never clash with a directory of the same name.
String webScrapperHtmlLocalPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.html') || lower.endsWith('.htm')) {
    return path;
  }
  return '$path.html';
}

final _invalidChars = RegExp(r'[<>:"\\|?*\x00-\x1f]');

String _sanitize(String segment) {
  if (segment.isEmpty || segment == '.' || segment == '..') {
    return '_';
  }
  return segment.replaceAll(_invalidChars, '_');
}

String _sanitizeQuery(String query) =>
    query.replaceAll(RegExp(r'[^\w.=\-]+'), '_');

const _maxNameLength = 120;

/// Shortens a too long file name, keeping its extension.
String _shorten(String fileName) {
  if (fileName.length <= _maxNameLength) {
    return fileName;
  }
  var extension = p.url.extension(fileName);
  if (extension.length > 12) {
    extension = '';
  }
  return '${fileName.substring(0, 80)}_${_fnv1a(fileName)}$extension';
}

/// 32 bits FNV-1a hash, stable across runs and platforms.
String _fnv1a(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    // hash * 0x01000193 split to stay below 2^53 on the web.
    hash = (hash * 0x193 + ((hash << 24) & 0xffffffff)) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
