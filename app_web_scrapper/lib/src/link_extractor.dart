import 'dart:convert';

import 'package:tekartik_html/html.dart';

import 'link.dart';

/// Extracts the links of html, css, javascript and json contents.
///
/// One extractor is shared by all the contents of a scrap so that the import
/// maps (`<script type="importmap">`) found in html pages are used to resolve
/// the bare module specifiers (`import * as THREE from 'three'`) of the
/// javascript files.
class WebScrapperLinkExtractor {
  /// When true, string literals of javascript and json contents that look
  /// like file paths (`'media.json'`, `"assets/logo.png"`) are also returned,
  /// resolved against the html document that led to them.
  final bool scanStrings;

  /// Import map entries collected from the html pages, bare specifier to
  /// url. Keys ending with `/` are prefixes.
  final importMap = <String, Uri>{};

  /// Creates an extractor, [scanStrings] (false by default) enables the
  /// string literal heuristic for javascript and json contents.
  WebScrapperLinkExtractor({this.scanStrings = false});

  /// Returns the links of an html [document] loaded from [uri].
  ///
  /// Handles `<base href>`, anchors (page links), stylesheets, icons,
  /// preloads, scripts (external and inline), import maps, images (including
  /// `srcset` and lazy loading `data-src`), media, iframes, meta refresh,
  /// `og:image`, `<style>` blocks and `style` attributes.
  List<WebScrapperLink> extractHtml(Document document, Uri uri) {
    final links = _Links();
    final root = document.html;
    var base = uri;
    for (final element in root.querySelectorAll('base')) {
      final href = _resolve(uri, element.getAttribute('href'));
      if (href != null) {
        base = href;
        break;
      }
    }
    for (final element in root.querySelectorAll('script')) {
      if (element.getAttribute('type')?.trim().toLowerCase() == 'importmap') {
        _addImportMap(element.text, base);
      }
    }

    void resource(String? value) => links.add(_resolve(base, value));
    void page(String? value) =>
        links.add(_resolve(base, value), kind: WebScrapperLinkKind.page);
    void srcset(String? value) {
      if (value == null) {
        return;
      }
      for (final candidate in value.split(',')) {
        final parts = candidate.trim().split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          resource(parts.first);
        }
      }
    }

    for (final element in root.querySelectorAll('*')) {
      String? attr(String name) => element.getAttribute(name);
      switch (element.tagName.toLowerCase()) {
        case 'a':
        case 'area':
          page(attr('href'));
        case 'link':
          final rels = (attr('rel') ?? '').toLowerCase().split(RegExp(r'\s+'));
          if (rels.any(_resourceRels.contains)) {
            resource(attr('href'));
          } else if (rels.any(_pageRels.contains)) {
            page(attr('href'));
          }
        case 'script':
          final src = attr('src');
          final type = attr('type')?.trim().toLowerCase();
          if (src != null) {
            resource(src);
          } else if (type == null ||
              type.isEmpty ||
              type == 'module' ||
              type.contains('javascript')) {
            links.addAll(
              extractJavaScript(element.text, base, documentUri: base),
            );
          }
        case 'img':
          resource(attr('src'));
          srcset(attr('srcset'));
          resource(attr('data-src'));
          srcset(attr('data-srcset'));
        case 'source':
          resource(attr('src'));
          srcset(attr('srcset'));
          srcset(attr('data-srcset'));
        case 'video':
          resource(attr('src'));
          resource(attr('poster'));
        case 'audio':
        case 'track':
        case 'embed':
        case 'iframe':
        case 'frame':
          resource(attr('src'));
          resource(attr('data-src'));
        case 'input':
          if (attr('type')?.toLowerCase() == 'image') {
            resource(attr('src'));
          }
        case 'object':
          resource(attr('data'));
        case 'image':
        case 'use':
          // svg
          final href = attr('href') ?? attr('xlink:href');
          if (href != null && !href.startsWith('#')) {
            resource(href);
          }
        case 'meta':
          final httpEquiv = attr('http-equiv')?.toLowerCase();
          final content = attr('content');
          if (httpEquiv == 'refresh' && content != null) {
            final match = RegExp(
              r'''url\s*=\s*['"]?([^'"]+)''',
              caseSensitive: false,
            ).firstMatch(content);
            page(match?.group(1));
          } else if (_imageMetas.contains(
            (attr('property') ?? attr('name'))?.toLowerCase(),
          )) {
            resource(content);
          }
        case 'style':
          links.addAll(extractCss(element.text, base));
        case 'body':
        case 'table':
        case 'td':
        case 'th':
          resource(attr('background'));
      }
      final style = attr('style');
      if (style != null && style.contains('url(')) {
        links.addAll(extractCss(style, base));
      }
    }
    return links.toList();
  }

  /// Returns the resources of a css [source] loaded from [uri]: `url(...)`
  /// values (images, fonts...) and `@import` stylesheets.
  List<WebScrapperLink> extractCss(String source, Uri uri) {
    final links = _Links();
    final css = source.replaceAll(_cssComment, '');
    for (final match in _cssImport.allMatches(css)) {
      links.add(_resolve(uri, match.group(1) ?? match.group(2)));
    }
    for (final match in _cssUrl.allMatches(css)) {
      links.add(
        _resolve(uri, match.group(1) ?? match.group(2) ?? match.group(3)),
      );
    }
    return links.toList();
  }

  /// Returns the resources of a javascript [source] loaded from [uri].
  ///
  /// Static imports and re-exports (`import x from './x.js'`,
  /// `export * from './y.js'`, `import './z.js'`), dynamic imports with a
  /// literal (`import('./page.js')`) and `new URL('./a.png', import.meta.url)`
  /// are resolved against [uri]. Bare specifiers are resolved through
  /// [importMap] and ignored when unknown.
  ///
  /// When [scanStrings] is set, string literals looking like file paths are
  /// also returned, resolved against [documentUri] (the html page running the
  /// script, as `fetch` does) or [uri] if null.
  List<WebScrapperLink> extractJavaScript(
    String source,
    Uri uri, {
    Uri? documentUri,
  }) {
    final links = _Links();
    final specifiers = <String>{};
    for (final regExp in [_jsStaticImport, _jsDynamicImport, _jsNewUrl]) {
      for (final match in regExp.allMatches(source)) {
        final specifier = match.group(2)!;
        specifiers.add(specifier);
        links.add(_resolveModule(uri, specifier));
      }
    }
    if (scanStrings) {
      final base = documentUri ?? uri;
      for (final regExp in _jsStrings) {
        for (final match in regExp.allMatches(source)) {
          final value = match.group(1)!;
          // Module specifiers are relative to the script, already handled.
          if (!specifiers.contains(value) && _looksLikeFilePath(value)) {
            links.add(_resolve(base, value.replaceAll(r'\/', '/')));
          }
        }
      }
    }
    return links.toList();
  }

  /// Returns the resources of a json [source] loaded from [uri] (manifests,
  /// media lists...).
  ///
  /// Only when [scanStrings] is set (returns an empty list otherwise): every
  /// key and string value looking like a file path is resolved against
  /// [documentUri] (the html page that led to the json) or [uri] if null.
  List<WebScrapperLink> extractJson(
    String source,
    Uri uri, {
    Uri? documentUri,
  }) {
    final links = _Links();
    if (!scanStrings) {
      return links.toList();
    }
    final base = documentUri ?? uri;
    void addString(String value) {
      if (_looksLikeFilePath(value)) {
        links.add(_resolve(base, value));
      }
    }

    void walk(Object? value) {
      if (value is String) {
        addString(value);
      } else if (value is Map) {
        for (final entry in value.entries) {
          if (entry.key is String) {
            addString(entry.key as String);
          }
          walk(entry.value);
        }
      } else if (value is List) {
        value.forEach(walk);
      }
    }

    try {
      walk(jsonDecode(source));
    } on FormatException {
      // Not valid json, fall back on the javascript string scanner.
      return extractJavaScript(source, uri, documentUri: documentUri);
    }
    return links.toList();
  }

  void _addImportMap(String source, Uri base) {
    try {
      final map = jsonDecode(source);
      if (map is Map && map['imports'] is Map) {
        (map['imports'] as Map).forEach((key, value) {
          if (key is String && value is String) {
            final uri = _resolve(base, value);
            if (uri != null) {
              importMap[key] = uri;
            }
          }
        });
      }
    } on FormatException {
      // Invalid import map, ignored as the browser would.
    }
  }

  Uri? _resolveModule(Uri uri, String specifier) {
    if (specifier.startsWith('./') ||
        specifier.startsWith('../') ||
        specifier.startsWith('/') ||
        specifier.startsWith('http://') ||
        specifier.startsWith('https://')) {
      return _resolve(uri, specifier);
    }
    final exact = importMap[specifier];
    if (exact != null) {
      return exact;
    }
    String? bestPrefix;
    for (final key in importMap.keys) {
      if (key.endsWith('/') &&
          specifier.startsWith(key) &&
          key.length > (bestPrefix?.length ?? 0)) {
        bestPrefix = key;
      }
    }
    if (bestPrefix != null) {
      return _resolve(
        importMap[bestPrefix]!,
        specifier.substring(bestPrefix.length),
      );
    }
    return null;
  }
}

/// Ordered set of links, the first kind found for an url wins.
class _Links {
  final _map = <Uri, WebScrapperLink>{};

  void add(
    Uri? uri, {
    WebScrapperLinkKind kind = WebScrapperLinkKind.resource,
  }) {
    if (uri != null) {
      _map.putIfAbsent(uri, () => WebScrapperLink(uri, kind: kind));
    }
  }

  void addAll(Iterable<WebScrapperLink> links) {
    for (final link in links) {
      _map.putIfAbsent(link.uri, () => link);
    }
  }

  List<WebScrapperLink> toList() => _map.values.toList();
}

/// Resolves [value] against [base], null for empty values, same page
/// fragments and non http(s) urls (data:, javascript:, mailto:...).
Uri? _resolve(Uri base, String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty || text.startsWith('#')) {
    return null;
  }
  try {
    final uri = base.resolveUri(Uri.parse(text));
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return null;
    }
    return uri.removeFragment();
  } on FormatException {
    return null;
  }
}

const _resourceRels = {
  'stylesheet',
  'icon',
  'apple-touch-icon',
  'apple-touch-icon-precomposed',
  'mask-icon',
  'preload',
  'modulepreload',
  'prefetch',
  'manifest',
  'image_src',
};

const _pageRels = {'next', 'prev'};

const _imageMetas = {'og:image', 'og:image:url', 'twitter:image'};

final _cssComment = RegExp(r'/\*[\s\S]*?\*/');
final _cssImport = RegExp(
  r'''@import\s+(?:'([^']*)'|"([^"]*)")''',
  caseSensitive: false,
);
final _cssUrl = RegExp(
  r'''url\(\s*(?:'([^']*)'|"([^"]*)"|([^)'"\s]*))\s*\)''',
  caseSensitive: false,
);

final _jsStaticImport = RegExp(
  r'''(?:^|[^\w$.])(?:import|export)\s*(?:[\w$*{}\s,]*?\s*from\s*)?(['"])([^'"\r\n]+)\1''',
  multiLine: true,
);
final _jsDynamicImport = RegExp(
  r'''(?:^|[^\w$.])import\s*\(\s*(['"])([^'"\r\n]+)\1\s*[,)]''',
  multiLine: true,
);
final _jsNewUrl = RegExp(
  r'''new\s+URL\s*\(\s*(['"])([^'"\r\n]+)\1\s*,\s*import\.meta\.url''',
);
final _jsStrings = [
  RegExp(r"""'((?:[^'\\\r\n]|\\.){3,512})'"""),
  RegExp(r'''"((?:[^"\\\r\n]|\\.){3,512})"'''),
  RegExp(r'''`([^`$\\\r\n]{3,512})`'''),
];

/// Extensions of the string literals considered as file paths.
const _fileExtensions = {
  'html', 'htm', 'css', 'js', 'mjs', 'json', 'webmanifest', 'xml', 'txt', //
  'csv', 'pdf', 'zip', 'wasm', 'bin', 'glb', 'gltf', 'ktx2', 'hdr', //
  'png', 'jpg', 'jpeg', 'gif', 'webp', 'avif', 'svg', 'ico', 'bmp', //
  'mp4', 'webm', 'ogv', 'mov', 'ogg', 'mp3', 'wav', 'm4a', 'aac', 'flac', //
  'opus', 'mid', 'midi', 'woff', 'woff2', 'ttf', 'otf', 'eot', //
};

final _filePath = RegExp(
  r'^(?:https?://|//|\.{0,2}/)?[\w\-.~%@+/]*[\w\-~%@+]\.(\w{1,11})(?:[?][^\s#]*)?$',
);

bool _looksLikeFilePath(String value) {
  final match = _filePath.firstMatch(value.replaceAll(r'\/', '/'));
  if (match == null) {
    return false;
  }
  return _fileExtensions.contains(match.group(1)!.toLowerCase());
}
