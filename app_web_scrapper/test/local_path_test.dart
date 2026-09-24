import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';
import 'package:test/test.dart';

String _path(String url) => webScrapperDefaultLocalPath(Uri.parse(url));

void main() {
  test('webScrapperDefaultLocalPath', () {
    expect(_path('https://example.com'), 'example.com/index.html');
    expect(_path('https://example.com/'), 'example.com/index.html');
    expect(_path('https://example.com/a/'), 'example.com/a/index.html');
    expect(_path('https://example.com/a/b.css'), 'example.com/a/b.css');
    expect(_path('https://example.com/about'), 'example.com/about');
    expect(_path('http://localhost:8080/a.js'), 'localhost_8080/a.js');
    // Default ports are not kept
    expect(_path('https://example.com:443/a.js'), 'example.com/a.js');
    expect(_path('https://example.com/app.js?v=2'), 'example.com/app_v=2.js');
    expect(
      _path('https://fonts.googleapis.com/css2?family=Poppins:wght@400;500'),
      'fonts.googleapis.com/css2_family=Poppins_wght_400_500',
    );
    expect(
      _path('https://example.com/?page=2'),
      'example.com/index_page=2.html',
    );
    expect(
      _path('https://example.com/my%20file.png'),
      'example.com/my file.png',
    );
    expect(_path('https://example.com/a%7Cb.png'), 'example.com/a_b.png');
    expect(_path('https://example.com/a//b.png'), 'example.com/a/_/b.png');
    final long = _path('https://example.com/${'x' * 200}.png');
    expect(long, startsWith('example.com/${'x' * 80}_'));
    expect(long, endsWith('.png'));
    expect(long.length, lessThan(120));
    // Stable
    expect(_path('https://example.com/${'x' * 200}.png'), long);
  });

  test('webScrapperHtmlLocalPath', () {
    expect(webScrapperHtmlLocalPath('a/index.html'), 'a/index.html');
    expect(webScrapperHtmlLocalPath('a/page.HTM'), 'a/page.HTM');
    expect(webScrapperHtmlLocalPath('a/about'), 'a/about.html');
    expect(webScrapperHtmlLocalPath('a/page_id=1.php'), 'a/page_id=1.php.html');
  });
}
