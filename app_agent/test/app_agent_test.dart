import 'dart:async';

import 'package:tekartik_app_agent/app_agent.dart';
import 'package:test/test.dart';

/// A fake page: the ids on screen, the clicks and the location, answering
/// the scripts [AgentWebPage] sends.
class _FakePage {
  var ids = <String>[];
  final clicks = <String>[];
  var location = '/';

  Future<Object?> evaluate(String expression) async {
    String? idOf() {
      var match = RegExp(
        r'flt-semantics-identifier=\\"([^\\]*)\\"',
      ).firstMatch(expression);
      return match?.group(1);
    }

    if (expression.startsWith('[...document.querySelectorAll')) {
      return ids;
    }
    if (expression.endsWith('.click()')) {
      clicks.add(idOf()!);
      return null;
    }
    if (expression.endsWith('!= null')) {
      return ids.contains(idOf());
    }
    if (expression.contains('aria-label')) {
      var id = idOf();
      return ids.contains(id) ? ' label of $id ' : null;
    }
    if (expression == 'location.pathname + location.hash') {
      return location;
    }
    if (expression == 'history.back()') {
      location = '/';
      return null;
    }
    throw UnsupportedError(expression);
  }
}

void main() {
  group('AgentUrlOptions', () {
    AgentUrlOptions of(String url) => AgentUrlOptions.fromUri(Uri.parse(url));

    test('query', () {
      expect(of('https://x.org/').needsSemantics, isFalse);
      expect(of('https://x.org/?semantics').semantics, isTrue);
      expect(of('https://x.org/?semantics').agent, isFalse);
      var agent = of('https://x.org/home?agent=1');
      expect(agent.agent, isTrue);
      expect(agent.needsSemantics, isTrue);
      expect(of('https://x.org/?agent=false').agent, isFalse);
      expect(of('https://x.org/?agent=0').agent, isFalse);
    });

    test('hash url', () {
      expect(of('https://x.org/#/home?agent').agent, isTrue);
      expect(of('https://x.org/#/home?semantics=on').semantics, isTrue);
      expect(of('https://x.org/#/home').needsSemantics, isFalse);
    });
  });

  group('AgentWebPage', () {
    test('ids, text, tap, location', () async {
      var fake = _FakePage()..ids = ['home', 'event-a"b'];
      var page = AgentWebPage(
        fake.evaluate,
        pollInterval: const Duration(milliseconds: 1),
      );
      expect(await page.ids(), ['home', 'event-a"b']);
      expect(await page.has('home'), isTrue);
      expect(await page.has('other'), isFalse);
      expect(await page.text('home'), 'label of home');
      expect(await page.text('other'), isNull);
      await page.tap('home');
      expect(fake.clicks, ['home']);
      fake.location = '/program';
      expect(await page.waitForLocation('/program'), '/program');
      await page.back();
      expect(await page.location(), '/');
    });

    test('waitFor', () async {
      var fake = _FakePage();
      var page = AgentWebPage(
        fake.evaluate,
        pollInterval: const Duration(milliseconds: 1),
      );
      Timer(const Duration(milliseconds: 20), () => fake.ids = ['a', 'b']);
      expect(await page.waitFor('a', others: ['b']), ['a', 'b']);
      await expectLater(
        page.waitFor('c', timeout: const Duration(milliseconds: 20)),
        throwsA(
          isA<TimeoutException>().having(
            (e) => e.message,
            'message',
            'missing c; on screen: a, b',
          ),
        ),
      );
    });
  });
}
