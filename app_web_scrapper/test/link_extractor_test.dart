import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';
import 'package:tekartik_html/html_html5lib.dart';
import 'package:test/test.dart';

final _base = Uri.parse('https://example.com/dir/page.html');

List<String> _urls(Iterable<WebScrapperLink> links) =>
    links.map((link) => link.uri.toString()).toList();

List<String> _pages(Iterable<WebScrapperLink> links) =>
    _urls(links.where((link) => link.isPage));

void main() {
  group('html', () {
    List<WebScrapperLink> extract(
      String html, {
      WebScrapperLinkExtractor? extractor,
    }) => (extractor ?? WebScrapperLinkExtractor()).extractHtml(
      htmlProviderHtml5Lib.createDocument(html: html),
      _base,
    );

    test('anchors', () {
      final links = extract('''
<a href="a.html">a</a>
<a href="/b/">b</a>
<a href="../c.html#section">c</a>
<a href="#top">top</a>
<a href="mailto:me@example.com">mail</a>
<a href="javascript:void(0)">js</a>
<a href="https://other.com/x">other</a>
<a>no href</a>
<area href="map.html">
''');
      expect(_pages(links), [
        'https://example.com/dir/a.html',
        'https://example.com/b/',
        'https://example.com/c.html',
        'https://other.com/x',
        'https://example.com/dir/map.html',
      ]);
      expect(_urls(links), _pages(links));
    });

    test('resources', () {
      final links = extract('''
<html><head>
<link rel="stylesheet" href="style.css">
<link rel="icon" href="/favicon.ico">
<link rel="preconnect" href="https://fonts.gstatic.com">
<link rel="pingback" href="/xmlrpc.php">
<link rel="modulepreload" href="mod.js">
<link rel="next" href="page2.html">
<meta property="og:image" content="https://example.com/og.png">
<meta http-equiv="refresh" content="5; url=moved.html">
<script src="lib.js"></script>
<style>body { background: url("bg.png") }</style>
</head><body style="background-image: url(body.png)">
<img src="img.png" srcset="img-1x.png 1x, img-2x.png 2x">
<img data-src="lazy.png">
<picture><source srcset="pic.webp" type="image/webp"></picture>
<video src="v.mp4" poster="poster.jpg"><track src="sub.vtt"></video>
<audio src="a.mp3"></audio>
<iframe src="frame.html"></iframe>
<object data="doc.pdf"></object>
<input type="image" src="button.png">
<input type="text" src="ignored.png">
<img src="data:image/png;base64,AAAA">
</body></html>
''');
      expect(_pages(links), [
        'https://example.com/dir/page2.html',
        'https://example.com/dir/moved.html',
      ]);
      expect(_urls(links.where((link) => !link.isPage)), [
        'https://example.com/dir/style.css',
        'https://example.com/favicon.ico',
        'https://example.com/dir/mod.js',
        'https://example.com/og.png',
        'https://example.com/dir/lib.js',
        'https://example.com/dir/bg.png',
        'https://example.com/dir/body.png',
        'https://example.com/dir/img.png',
        'https://example.com/dir/img-1x.png',
        'https://example.com/dir/img-2x.png',
        'https://example.com/dir/lazy.png',
        'https://example.com/dir/pic.webp',
        'https://example.com/dir/v.mp4',
        'https://example.com/dir/poster.jpg',
        'https://example.com/dir/sub.vtt',
        'https://example.com/dir/a.mp3',
        'https://example.com/dir/frame.html',
        'https://example.com/dir/doc.pdf',
        'https://example.com/dir/button.png',
      ]);
    });

    test('base', () {
      final links = extract(
        '<head><base href="/root/"></head><body><img src="a.png"></body>',
      );
      expect(_urls(links), ['https://example.com/root/a.png']);
    });

    test('import map and inline module', () {
      final extractor = WebScrapperLinkExtractor();
      final links = extract('''
<script type="importmap">
{ "imports": {
  "three": "https://cdn.example.com/three/three.module.js",
  "three/addons/": "https://cdn.example.com/three/addons/",
  "local": "./vendor/local.js"
} }
</script>
<script type="module">
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import local from 'local';
import unknown from 'unknown';
import './app.js';
</script>
''', extractor: extractor);
      expect(_urls(links), [
        'https://cdn.example.com/three/three.module.js',
        'https://cdn.example.com/three/addons/controls/OrbitControls.js',
        'https://example.com/dir/vendor/local.js',
        'https://example.com/dir/app.js',
      ]);
      expect(extractor.importMap.keys, ['three', 'three/addons/', 'local']);
    });
  });

  test('css', () {
    final links = WebScrapperLinkExtractor().extractCss('''
@import "theme.css";
@import url('print.css') print;
/* url(commented.png) */
body { background: url(img/bg.png) no-repeat; }
.a { background-image: url( "../up.jpg" ); }
@font-face { src: url('fonts/f.woff2') format('woff2'), url(fonts/f.woff); }
.b { mask: url(#mask); background: url(data:image/png;base64,AAAA); }
''', _base);
    expect(_urls(links), [
      'https://example.com/dir/theme.css',
      'https://example.com/dir/print.css',
      'https://example.com/dir/img/bg.png',
      'https://example.com/up.jpg',
      'https://example.com/dir/fonts/f.woff2',
      'https://example.com/dir/fonts/f.woff',
    ]);
    expect(links.every((link) => !link.isPage), isTrue);
  });

  group('javascript', () {
    final scriptUri = Uri.parse('https://example.com/src/app.js');

    test('imports', () {
      final links = WebScrapperLinkExtractor().extractJavaScript('''
import { a, b } from './a.js';
import def, {
  c,
} from "../b.js";
import * as ns from './c.js';
import './side_effect.js';
export * from './d.js';
export { e } from './e.js';
const page = await import('./pages/page.js');
const other = import("./other.js", { with: { type: 'json' } });
const url = new URL('./img/logo.png', import.meta.url);
import bare from 'bare';
const s = 'not/followed.png';
obj.import('./method.js');
import{m}from"./minified.js";export{n}from"./minified2.js";
''', scriptUri);
      expect(_urls(links), [
        'https://example.com/src/a.js',
        'https://example.com/b.js',
        'https://example.com/src/c.js',
        'https://example.com/src/side_effect.js',
        'https://example.com/src/d.js',
        'https://example.com/src/e.js',
        'https://example.com/src/minified.js',
        'https://example.com/src/minified2.js',
        'https://example.com/src/pages/page.js',
        'https://example.com/src/other.js',
        'https://example.com/src/img/logo.png',
      ]);
    });

    test('scanStrings', () {
      final documentUri = Uri.parse('https://example.com/index.html');
      final source = r'''
import { x } from './x.js';
export async function loadManifest(url = 'media.json') {}
const logo = "assets/logo.png";
const escaped = "assets\/escaped.png";
const tpl = `img/${name}.png`;
const plain = `img/plain.webp`;
const cdn = 'https://cdn.example.com/lib.js';
const notFiles = ['kinetixarm', 'text/css', 'a b.png', 'v1.2', '/__log', 'user@example.com'];
''';
      expect(
        _urls(
          WebScrapperLinkExtractor().extractJavaScript(
            source,
            scriptUri,
            documentUri: documentUri,
          ),
        ),
        ['https://example.com/src/x.js'],
      );
      final links = WebScrapperLinkExtractor(
        scanStrings: true,
      ).extractJavaScript(source, scriptUri, documentUri: documentUri);
      expect(_urls(links), [
        'https://example.com/src/x.js',
        // Relative to the document, as fetch would do.
        'https://example.com/media.json',
        'https://cdn.example.com/lib.js',
        'https://example.com/assets/logo.png',
        'https://example.com/assets/escaped.png',
        'https://example.com/img/plain.webp',
      ]);
    });
  });

  test('json', () {
    final jsonUri = Uri.parse('https://example.com/data/media.json');
    const source = '''
{
  "media": [
    { "id": "snap_1", "kind": "video", "src": "input/snap_1.mp4", "poster": "posters/snap_1.jpg", "width": 1080 },
    { "id": "snap_2", "src": "https://cdn.example.com/snap_2.webm" }
  ],
  "assets/key.png": ["assets/value.png"]
}
''';
    expect(WebScrapperLinkExtractor().extractJson(source, jsonUri), isEmpty);
    final extractor = WebScrapperLinkExtractor(scanStrings: true);
    expect(_urls(extractor.extractJson(source, jsonUri)), [
      'https://example.com/data/input/snap_1.mp4',
      'https://example.com/data/posters/snap_1.jpg',
      'https://cdn.example.com/snap_2.webm',
      'https://example.com/data/assets/key.png',
      'https://example.com/data/assets/value.png',
    ]);
    expect(
      _urls(
        extractor.extractJson(
          source,
          jsonUri,
          documentUri: Uri.parse('https://example.com/'),
        ),
      ).first,
      'https://example.com/input/snap_1.mp4',
    );
  });

  test('webScrapperContentFormat', () {
    expect(
      webScrapperContentFormat(contentType: 'text/html; charset=utf-8'),
      WebScrapperContentFormat.html,
    );
    expect(
      webScrapperContentFormat(contentType: 'text/css', path: '/a.js'),
      WebScrapperContentFormat.css,
    );
    expect(
      webScrapperContentFormat(contentType: 'image/png', path: '/a.js'),
      WebScrapperContentFormat.other,
    );
    // Generic content type, trust the extension
    expect(
      webScrapperContentFormat(
        contentType: 'application/octet-stream',
        path: '/a.mjs',
      ),
      WebScrapperContentFormat.javascript,
    );
    expect(
      webScrapperContentFormat(path: 'dir.json/file'),
      WebScrapperContentFormat.other,
    );
    expect(
      webScrapperContentFormat(path: '/manifest.webmanifest'),
      WebScrapperContentFormat.json,
    );
    expect(webScrapperContentFormat(), WebScrapperContentFormat.other);
  });
}
