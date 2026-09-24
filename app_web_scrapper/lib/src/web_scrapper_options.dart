import 'dart:async';

import 'local_path.dart';
import 'web_scrapper.dart';

/// Called for every successfully fetched (or cached) content before its
/// links are followed, see [WebScrapperOptions.onContent].
typedef WebScrapperContentHandler =
    FutureOr<void> Function(WebScrapperContent content);

/// Called for every processed url (downloaded, cached or failed), see
/// [WebScrapperOptions.onEntry].
typedef WebScrapperEntryHandler = void Function(WebScrapperEntry entry);

/// Options of a [WebScrapper].
class WebScrapperOptions {
  /// Maximum page depth, null for no limit.
  ///
  /// Start urls are at depth 0, pages they link to (`<a href>`) at depth 1...
  /// Resources (images, stylesheets, scripts...) keep the depth of the content
  /// referencing them so a page at [maxDepth] is still saved complete.
  /// `0` only saves the start pages and their resources.
  final int? maxDepth;

  /// Download the resources (images, stylesheets, scripts, fonts, media...)
  /// hosted on other domains, false by default.
  final bool followExternalResources;

  /// Download the pages on other domains linked from pages of the scrapped
  /// domains, false by default.
  ///
  /// Only one hop is made: the links of an external page are only followed
  /// when they come back to a scrapped domain (and its resources only when
  /// [followExternalResources] is set).
  final bool followExternalLinks;

  /// Also follow the string literals of javascript and json contents that
  /// look like file paths (`'media.json'`, `"img/logo.png"`), false by
  /// default.
  ///
  /// Useful for single page applications loading data with `fetch`, at the
  /// cost of some requests failing on false positives.
  final bool scanStrings;

  /// Extra hosts considered as part of the scrapped site in addition to the
  /// hosts of the start urls (i.e. `www.example.com` for `example.com`).
  ///
  /// With an explicit port, the value is `host:port`.
  final List<String>? hosts;

  /// Filter called for every url found (not for the start urls), return
  /// false to ignore it.
  final bool Function(Uri uri)? filter;

  /// Maximum number of urls processed (downloaded, cached or failed), null
  /// for no limit.
  final int? maxFiles;

  /// Number of concurrent requests, 4 by default.
  final int concurrency;

  /// Delay before each request, to be gentle with the server.
  final Duration? delay;

  /// Download files again even if already present in the output directory.
  ///
  /// By default an existing file is not downloaded again: it is read back
  /// from the output directory to find its links, which makes an interrupted
  /// scrap resume quickly.
  final bool force;

  /// Extra request headers (user agent, cookie, authorization...).
  final Map<String, String>? headers;

  /// Maps an url to the relative posix path of the file saved in the output
  /// directory, return null to not save it.
  ///
  /// Defaults to [webScrapperDefaultLocalPath] (`<host>/<path>`). Html
  /// contents always get `.html` appended when their path does not end with
  /// `.html` or `.htm`.
  final String? Function(Uri uri)? localPath;

  /// Called for every successfully fetched (or cached) content before its
  /// links are followed.
  ///
  /// The handler can parse the content ([WebScrapperContent.text],
  /// [WebScrapperContent.document], [WebScrapperContent.readBytes]) and
  /// add or remove links in [WebScrapperContent.links]. An exception marks the
  /// entry as failed and its links are not followed.
  final WebScrapperContentHandler? onContent;

  /// Called for every processed url (downloaded, cached or failed), for
  /// progress reporting.
  final WebScrapperEntryHandler? onEntry;

  /// Creates options, all optional, see each field for its default.
  const WebScrapperOptions({
    this.maxDepth,
    this.followExternalResources = false,
    this.followExternalLinks = false,
    this.scanStrings = false,
    this.hosts,
    this.filter,
    this.maxFiles,
    this.concurrency = 4,
    this.delay,
    this.force = false,
    this.headers,
    this.localPath,
    this.onContent,
    this.onEntry,
  });
}
