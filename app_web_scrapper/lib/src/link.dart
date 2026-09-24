/// How a link was referenced, which drives depth and external domain rules.
enum WebScrapperLinkKind {
  /// A navigation link (`<a href>`, `<area href>`, meta refresh...).
  ///
  /// Following it increases the depth by one and, on another domain, it is
  /// only followed when `followExternalLinks` is set.
  page,

  /// A resource needed to render the content (image, stylesheet, script,
  /// font, media, iframe, javascript import...).
  ///
  /// It keeps the depth of the content referencing it and, on another domain,
  /// it is only followed when `followExternalResources` is set.
  resource,
}

/// A link found in a content, resolved to an absolute http(s) url.
class WebScrapperLink {
  /// Url without fragment, absolute http(s) when found by the extractor,
  /// possibly relative when added by a content handler (resolved against the
  /// content url).
  final Uri uri;

  /// Page or resource.
  final WebScrapperLinkKind kind;

  /// Creates a link to [uri] (fragment is removed) of the given [kind]
  /// (resource by default).
  WebScrapperLink(Uri uri, {this.kind = WebScrapperLinkKind.resource})
    : uri = uri.removeFragment();

  /// Creates a page link to [uri].
  WebScrapperLink.page(Uri uri) : this(uri, kind: WebScrapperLinkKind.page);

  /// True for a page link.
  bool get isPage => kind == WebScrapperLinkKind.page;

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) =>
      other is WebScrapperLink && other.uri == uri && other.kind == kind;

  @override
  String toString() => '${kind.name} $uri';
}

/// Format of a content, deciding how links are extracted from it.
enum WebScrapperContentFormat {
  /// Html page, links are read from the parsed document.
  html,

  /// Css stylesheet, `url()` and `@import` are followed.
  css,

  /// JavaScript, static and dynamic imports are followed.
  javascript,

  /// Json, only scanned when `scanStrings` is set.
  json,

  /// Anything else (images, fonts, media, archives...), never scanned.
  other;

  /// True if the content is text that is scanned for links.
  bool get isText => this != other;
}

const _textExtensions = <String, WebScrapperContentFormat>{
  '.html': WebScrapperContentFormat.html,
  '.htm': WebScrapperContentFormat.html,
  '.xhtml': WebScrapperContentFormat.html,
  '.css': WebScrapperContentFormat.css,
  '.js': WebScrapperContentFormat.javascript,
  '.mjs': WebScrapperContentFormat.javascript,
  '.json': WebScrapperContentFormat.json,
  '.webmanifest': WebScrapperContentFormat.json,
};

/// Finds the format of a content from its [contentType] header value if any
/// (i.e. `text/html; charset=utf-8`), falling back to the extension of [path]
/// (url path or local file path).
///
/// Returns [WebScrapperContentFormat.other] when neither is known.
WebScrapperContentFormat webScrapperContentFormat({
  String? contentType,
  String? path,
}) {
  var mimeType = contentType?.split(';').first.trim().toLowerCase();
  if (mimeType != null && mimeType.isNotEmpty) {
    switch (mimeType) {
      case 'text/html':
      case 'application/xhtml+xml':
        return WebScrapperContentFormat.html;
      case 'text/css':
        return WebScrapperContentFormat.css;
      case 'text/javascript':
      case 'application/javascript':
      case 'application/x-javascript':
      case 'application/ecmascript':
      case 'text/ecmascript':
        return WebScrapperContentFormat.javascript;
      case 'application/json':
      case 'application/manifest+json':
      case 'text/json':
        return WebScrapperContentFormat.json;
    }
    // Generic types (text/plain, application/octet-stream) are often wrong
    // on static hosts, trust the extension then.
    if (!(mimeType == 'text/plain' ||
        mimeType == 'application/octet-stream' ||
        mimeType == 'binary/octet-stream')) {
      return WebScrapperContentFormat.other;
    }
  }
  if (path != null) {
    var lower = path.toLowerCase();
    var dot = lower.lastIndexOf('.');
    if (dot >= 0 && dot > lower.lastIndexOf('/')) {
      return _textExtensions[lower.substring(dot)] ??
          WebScrapperContentFormat.other;
    }
  }
  return WebScrapperContentFormat.other;
}
