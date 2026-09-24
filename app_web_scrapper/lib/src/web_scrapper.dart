import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/utils/read_write.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:tekartik_app_http/app_http.dart'
    show
        HttpClientFactory,
        httpClientFactoryUniversal,
        isHttpStatusCodeSuccessful;
import 'package:tekartik_html/html_html5lib.dart';

import 'link.dart';
import 'link_extractor.dart';
import 'local_path.dart';
import 'web_scrapper_options.dart';

/// A fetched (or cached) content, given to [WebScrapperOptions.onContent].
class WebScrapperContent {
  /// Url of the content, after redirects.
  final Uri uri;

  /// Requested url, different from [uri] after a redirect.
  final Uri requestUri;

  /// How the content was referenced.
  final WebScrapperLinkKind kind;

  /// Page depth, 0 for the start urls.
  final int depth;

  /// True if the content is not on one of the scrapped hosts.
  final bool isExternal;

  /// Url of the content referencing this one, null for a start url.
  final Uri? referrer;

  /// True if the content was read from the output directory instead of
  /// being downloaded (see [WebScrapperOptions.force]).
  final bool fromCache;

  /// Http status code, null when [fromCache].
  final int? statusCode;

  /// Response headers (lowercase keys), empty when [fromCache].
  final Map<String, String> headers;

  /// Format deciding how links were extracted.
  final WebScrapperContentFormat format;

  /// Relative posix path in the output directory, null if not saved.
  final String? localPath;

  /// Saved file, null if not saved.
  final File? file;

  /// Decoded text for html, css, javascript and json contents, null
  /// otherwise.
  final String? text;

  /// Parsed document for html contents, null otherwise.
  final Document? document;

  /// Links found in the content, only the ones matching the options
  /// (depth, domains, filter) are followed.
  ///
  /// [WebScrapperOptions.onContent] can add (i.e. urls found by a custom
  /// parser, relative urls are resolved against [uri]) or remove links
  /// before they are followed.
  final List<WebScrapperLink> links;

  final Uint8List? _bytes;

  WebScrapperContent._({
    required this.uri,
    required this.requestUri,
    required this.kind,
    required this.depth,
    required this.isExternal,
    required this.referrer,
    required this.fromCache,
    required this.statusCode,
    required this.headers,
    required this.format,
    required this.localPath,
    required this.file,
    required this.text,
    required this.document,
    required this.links,
    required this._bytes,
  });

  /// Content type header value (i.e. `text/html; charset=utf-8`), null if
  /// unknown or [fromCache].
  String? get contentType => headers['content-type'];

  /// Returns the raw bytes, from memory or read back from [file] for large
  /// binary contents that were streamed to disk.
  Future<Uint8List> readBytes() async {
    final bytes = _bytes;
    if (bytes != null) {
      return bytes;
    }
    return file!.readAsBytes();
  }

  @override
  String toString() => '$uri (${format.name}, depth $depth)';
}

/// Status of a processed url.
enum WebScrapperEntryStatus {
  /// Downloaded (and saved if an output directory is set).
  downloaded,

  /// Already present in the output directory, read back to follow its links.
  cached,

  /// Failed: http error status, network error or content handler error.
  failed,
}

/// Report of a processed url, given to [WebScrapperOptions.onEntry] and
/// listed in [WebScrapperResult.entries].
class WebScrapperEntry {
  /// Requested url.
  final Uri uri;

  /// Url after redirects, same as [uri] when not redirected or failed
  /// before the response.
  final Uri finalUri;

  /// How the url was referenced.
  final WebScrapperLinkKind kind;

  /// Page depth, 0 for the start urls.
  final int depth;

  /// Url of the content referencing this one, null for a start url.
  final Uri? referrer;

  /// Download result.
  final WebScrapperEntryStatus status;

  /// Http status code, null when cached or on network error.
  final int? statusCode;

  /// Relative posix path in the output directory, null if not saved.
  final String? localPath;

  /// Size in bytes, null when failed.
  final int? size;

  /// Error when [status] is [WebScrapperEntryStatus.failed].
  final Object? error;

  /// Stack trace of [error] when it is an exception.
  final StackTrace? stackTrace;

  WebScrapperEntry._({
    required this.uri,
    required this.finalUri,
    required this.kind,
    required this.depth,
    required this.referrer,
    required this.status,
    this.statusCode,
    this.localPath,
    this.size,
    this.error,
    this.stackTrace,
  });

  /// True when [status] is [WebScrapperEntryStatus.failed].
  bool get isFailed => status == WebScrapperEntryStatus.failed;

  @override
  String toString() {
    final sb = StringBuffer('${status.name} $uri');
    if (finalUri != uri) {
      sb.write(' => $finalUri');
    }
    if (statusCode != null) {
      sb.write(' [$statusCode]');
    }
    if (localPath != null) {
      sb.write(' -> $localPath');
    }
    if (error != null) {
      sb.write(': $error');
    }
    return sb.toString();
  }
}

/// Result of [WebScrapper.run].
class WebScrapperResult {
  /// Processed urls in completion order.
  final List<WebScrapperEntry> entries;

  /// Creates a result from its [entries].
  WebScrapperResult(this.entries);

  /// Entries with [WebScrapperEntryStatus.downloaded].
  Iterable<WebScrapperEntry> get downloaded =>
      entries.where((e) => e.status == WebScrapperEntryStatus.downloaded);

  /// Entries with [WebScrapperEntryStatus.cached].
  Iterable<WebScrapperEntry> get cached =>
      entries.where((e) => e.status == WebScrapperEntryStatus.cached);

  /// Entries with [WebScrapperEntryStatus.failed].
  Iterable<WebScrapperEntry> get failed => entries.where((e) => e.isFailed);

  @override
  String toString() =>
      '${entries.length} urls: ${downloaded.length} downloaded, '
      '${cached.length} cached, ${failed.length} failed';
}

/// Static web site scrapper.
///
/// Fetches the start urls, extracts their links (html pages, stylesheets,
/// javascript modules and optionally json/javascript strings) and follows
/// them according to [options], saving every file in [outDirectory] as
/// `<host>/<path>`.
class WebScrapper {
  /// Absolute http(s) urls to start from (depth 0), their hosts define the
  /// scrapped site.
  final List<Uri> startUris;

  /// Output directory, null to save nothing (contents are then only given
  /// to [WebScrapperOptions.onContent]).
  final Directory? outDirectory;

  /// Options.
  final WebScrapperOptions options;

  /// Http client factory used to create the client of a run.
  final HttpClientFactory httpClientFactory;

  /// Html provider used to parse the pages.
  final HtmlProvider htmlProvider;

  /// Creates a scrapper for [startUris] (absolute http(s) urls, at least
  /// one) saving to [outDirectory] (a fs_shim directory, possibly in memory).
  ///
  /// [httpClientFactory] defaults to `httpClientFactoryUniversal` and
  /// [htmlProvider] to `htmlProviderHtml5Lib`, override them for tests.
  ///
  /// Throws an [ArgumentError] when a start url is not an absolute http(s)
  /// url.
  WebScrapper({
    required Iterable<Uri> startUris,
    this.outDirectory,
    WebScrapperOptions? options,
    HttpClientFactory? httpClientFactory,
    HtmlProvider? htmlProvider,
  }) : startUris = startUris.map((uri) => uri.removeFragment()).toList(),
       options = options ?? const WebScrapperOptions(),
       httpClientFactory = httpClientFactory ?? httpClientFactoryUniversal,
       htmlProvider = htmlProvider ?? htmlProviderHtml5Lib {
    if (this.startUris.isEmpty) {
      throw ArgumentError.value(startUris, 'startUris', 'empty');
    }
    for (final uri in this.startUris) {
      if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
        throw ArgumentError.value(uri, 'startUris', 'not an http(s) url');
      }
    }
  }

  /// Scraps the site, returns when every url has been processed.
  ///
  /// Http, network, file system and [WebScrapperOptions.onContent] errors
  /// are reported as failed entries; only an error thrown by
  /// [WebScrapperOptions.onEntry] aborts the run (the returned future then
  /// completes with it).
  Future<WebScrapperResult> run() => _WebScrapperRun(this).run();
}

class _Item {
  final Uri uri;
  final WebScrapperLinkKind kind;
  final int depth;
  final Uri? referrer;

  /// Html page the content comes from, to resolve javascript/json strings.
  final Uri? documentUri;

  _Item({
    required this.uri,
    required this.kind,
    required this.depth,
    this.referrer,
    this.documentUri,
  });
}

String _hostKey(Uri uri) {
  final host = uri.host.toLowerCase();
  return uri.hasPort ? '$host:${uri.port}' : host;
}

/// Same url whatever the scheme.
String _urlKey(Uri uri) =>
    '${_hostKey(uri)}${uri.path.isEmpty ? '/' : uri.path}'
    '${uri.hasQuery ? '?${uri.query}' : ''}';

class _WebScrapperRun {
  final WebScrapper scrapper;
  final WebScrapperOptions options;
  final WebScrapperLinkExtractor extractor;
  final _queue = Queue<_Item>();
  final _seen = <String>{};
  final _hosts = <String>{};
  final _entries = <WebScrapperEntry>[];
  var _queuedCount = 0;
  late http.Client _client;

  _WebScrapperRun(this.scrapper)
    : options = scrapper.options,
      extractor = WebScrapperLinkExtractor(
        scanStrings: scrapper.options.scanStrings,
      );

  Future<WebScrapperResult> run() async {
    _hosts.addAll(scrapper.startUris.map(_hostKey));
    _hosts.addAll(
      (options.hosts ?? const <String>[]).map((h) => h.toLowerCase()),
    );
    for (final uri in scrapper.startUris) {
      _enqueue(_Item(uri: uri, kind: WebScrapperLinkKind.page, depth: 0));
    }
    _client = scrapper.httpClientFactory.newClient();
    try {
      await _drain();
    } finally {
      _client.close();
    }
    return WebScrapperResult(_entries);
  }

  bool _isInternal(Uri uri) => _hosts.contains(_hostKey(uri));

  void _enqueue(_Item item) {
    final maxFiles = options.maxFiles;
    if (maxFiles != null && _queuedCount >= maxFiles) {
      return;
    }
    if (_seen.add(_urlKey(item.uri))) {
      _queuedCount++;
      _queue.add(item);
    }
  }

  Future<void> _drain() {
    final completer = Completer<void>();
    final concurrency = options.concurrency < 1 ? 1 : options.concurrency;
    var running = 0;

    void pump() {
      if (completer.isCompleted) {
        return;
      }
      while (running < concurrency && _queue.isNotEmpty) {
        final item = _queue.removeFirst();
        running++;
        _process(item).then(
          (_) {
            running--;
            pump();
          },
          onError: (Object error, StackTrace stackTrace) {
            running--;
            _queue.clear();
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
        );
      }
      if (running == 0 && _queue.isEmpty && !completer.isCompleted) {
        completer.complete();
      }
    }

    pump();
    return completer.future;
  }

  Future<void> _process(_Item item) async {
    WebScrapperEntry entry;
    try {
      entry = await _processItem(item);
    } catch (error, stackTrace) {
      entry = WebScrapperEntry._(
        uri: item.uri,
        finalUri: item.uri,
        kind: item.kind,
        depth: item.depth,
        referrer: item.referrer,
        status: WebScrapperEntryStatus.failed,
        error: error,
        stackTrace: stackTrace,
      );
    }
    _entries.add(entry);
    options.onEntry?.call(entry);
  }

  String? _localPath(Uri uri) =>
      (options.localPath ?? webScrapperDefaultLocalPath)(uri);

  File _file(String localPath) {
    final directory = scrapper.outDirectory!;
    return directory.fs.file(
      directory.fs.path.joinAll([directory.path, ...p.url.split(localPath)]),
    );
  }

  Future<WebScrapperEntry> _processItem(_Item item) async {
    if (scrapper.outDirectory != null && !options.force) {
      final localPath = _localPath(item.uri);
      if (localPath != null) {
        for (final candidate in {
          localPath,
          webScrapperHtmlLocalPath(localPath),
        }) {
          final file = _file(candidate);
          if (await file.fs.isFile(file.path)) {
            return _processCached(item, candidate, file);
          }
        }
      }
    }
    return _download(item);
  }

  Future<WebScrapperEntry> _processCached(
    _Item item,
    String localPath,
    File file,
  ) async {
    final format = webScrapperContentFormat(path: localPath);
    final bytes = format.isText ? await file.readAsBytes() : null;
    final content = _content(
      item,
      uri: item.uri,
      fromCache: true,
      statusCode: null,
      headers: const {},
      format: format,
      localPath: localPath,
      file: file,
      bytes: bytes,
    );
    await _handleContent(item, content);
    return WebScrapperEntry._(
      uri: item.uri,
      finalUri: item.uri,
      kind: item.kind,
      depth: item.depth,
      referrer: item.referrer,
      status: WebScrapperEntryStatus.cached,
      localPath: localPath,
      size: bytes?.length ?? (await file.stat()).size,
    );
  }

  Future<WebScrapperEntry> _download(_Item item) async {
    final delay = options.delay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    final request = http.Request('GET', item.uri);
    final headers = options.headers;
    if (headers != null) {
      request.headers.addAll(headers);
    }
    final response = await _client.send(request);
    var uri = item.uri;
    if (response case http.BaseResponseWithUrl(:final url)) {
      uri = url.removeFragment();
      // Don't fetch the redirection target again.
      _seen.add(_urlKey(uri));
    }
    if (!isHttpStatusCodeSuccessful(response.statusCode)) {
      try {
        await response.stream.drain<void>();
      } catch (_) {
        // ignore
      }
      return WebScrapperEntry._(
        uri: item.uri,
        finalUri: uri,
        kind: item.kind,
        depth: item.depth,
        referrer: item.referrer,
        status: WebScrapperEntryStatus.failed,
        statusCode: response.statusCode,
        error: 'http status ${response.statusCode}',
      );
    }
    final format = webScrapperContentFormat(
      contentType: response.headers['content-type'],
      path: uri.path,
    );
    var localPath = scrapper.outDirectory == null ? null : _localPath(uri);
    if (localPath != null && format == WebScrapperContentFormat.html) {
      localPath = webScrapperHtmlLocalPath(localPath);
    }
    final file = localPath == null ? null : _file(localPath);
    Uint8List? bytes;
    int size;
    if (format.isText || file == null) {
      bytes = await response.stream.toBytes();
      size = bytes.length;
      if (file != null) {
        await writeBytes(file, bytes);
      }
    } else {
      try {
        await streamToFile(response.stream, file);
      } catch (_) {
        // Don't leave a partial file that would be taken as cached.
        try {
          await file.delete();
        } catch (_) {
          // ignore
        }
        rethrow;
      }
      size = (await file.stat()).size;
    }
    final content = _content(
      item,
      uri: uri,
      fromCache: false,
      statusCode: response.statusCode,
      headers: response.headers,
      format: format,
      localPath: localPath,
      file: file,
      bytes: bytes,
    );
    await _handleContent(item, content);
    return WebScrapperEntry._(
      uri: item.uri,
      finalUri: uri,
      kind: item.kind,
      depth: item.depth,
      referrer: item.referrer,
      status: WebScrapperEntryStatus.downloaded,
      statusCode: response.statusCode,
      localPath: localPath,
      size: size,
    );
  }

  WebScrapperContent _content(
    _Item item, {
    required Uri uri,
    required bool fromCache,
    required int? statusCode,
    required Map<String, String> headers,
    required WebScrapperContentFormat format,
    required String? localPath,
    required File? file,
    required Uint8List? bytes,
  }) {
    String? text;
    Document? document;
    var links = <WebScrapperLink>[];
    if (format.isText && bytes != null) {
      text = _decode(bytes, headers['content-type']);
      switch (format) {
        case WebScrapperContentFormat.html:
          document = scrapper.htmlProvider.createDocument(html: text);
          links = extractor.extractHtml(document, uri);
        case WebScrapperContentFormat.css:
          links = extractor.extractCss(text, uri);
        case WebScrapperContentFormat.javascript:
          links = extractor.extractJavaScript(
            text,
            uri,
            documentUri: item.documentUri,
          );
        case WebScrapperContentFormat.json:
          links = extractor.extractJson(
            text,
            uri,
            documentUri: item.documentUri,
          );
        case WebScrapperContentFormat.other:
          break;
      }
    }
    return WebScrapperContent._(
      uri: uri,
      requestUri: item.uri,
      kind: item.kind,
      depth: item.depth,
      isExternal: !_isInternal(uri),
      referrer: item.referrer,
      fromCache: fromCache,
      statusCode: statusCode,
      headers: headers,
      format: format,
      localPath: localPath,
      file: file,
      text: text,
      document: document,
      links: links,
      bytes: bytes,
    );
  }

  Future<void> _handleContent(_Item item, WebScrapperContent content) async {
    await options.onContent?.call(content);
    final documentUri = content.format == WebScrapperContentFormat.html
        ? content.uri
        : (item.documentUri ?? content.uri);
    for (final link in content.links) {
      // Links added by onContent may be relative.
      final uri = content.uri.resolveUri(link.uri).removeFragment();
      if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
        continue;
      }
      final internal = _isInternal(uri);
      int depth;
      if (link.isPage) {
        if (!internal && (!options.followExternalLinks || content.isExternal)) {
          continue;
        }
        depth = content.depth + 1;
        final maxDepth = options.maxDepth;
        if (maxDepth != null && depth > maxDepth) {
          continue;
        }
      } else {
        if (!internal && !options.followExternalResources) {
          continue;
        }
        depth = content.depth;
      }
      if (options.filter?.call(uri) == false) {
        continue;
      }
      _enqueue(
        _Item(
          uri: uri,
          kind: link.kind,
          depth: depth,
          referrer: content.uri,
          documentUri: documentUri,
        ),
      );
    }
  }
}

String _decode(Uint8List bytes, String? contentType) {
  final charset = RegExp(
    r'charset\s*=\s*"?([\w\-]+)',
    caseSensitive: false,
  ).firstMatch(contentType ?? '')?.group(1)?.toLowerCase();
  if (charset == 'iso-8859-1' ||
      charset == 'latin1' ||
      charset == 'windows-1252') {
    return latin1.decode(bytes, allowInvalid: true);
  }
  return utf8.decode(bytes, allowMalformed: true);
}
