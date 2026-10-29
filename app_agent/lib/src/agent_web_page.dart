import 'dart:async';
import 'dart:convert';

import 'agent_command.dart';

/// The global object of the web js bridge of an app opened with `?agent`
/// (`window.tekartikAgent`): `commands()` (the descriptions of its
/// commands), `run(name, args)` (a promise of `{ok, result}` or `{ok,
/// error}`), `help()`.
const agentBridgeName = 'tekartikAgent';

/// Evaluates a javascript [expression] in a page and returns its json value
/// (`Runtime.evaluate` with `returnByValue` of the Chrome DevTools protocol,
/// Playwright `page.evaluate`...), awaiting its promise when
/// [awaitPromise].
typedef AgentEvaluate =
    Future<Object?> Function(String expression, {bool awaitPromise});

/// Drives a Flutter web app by its semantics ids: the
/// `flt-semantics-identifier` attributes of the semantics DOM, set by
/// `Semantics(identifier:)` (`AgentId` of tekartik_app_agent_flutter). The
/// app must build its semantics (`?semantics` or `?agent` in its url, see
/// `AgentUrlOptions`).
///
/// Everything goes through [evaluate], so any page driver works.
class AgentWebPage {
  /// Evaluates the scripts in the page.
  final AgentEvaluate evaluate;

  /// The delay between two looks at the page while waiting.
  final Duration pollInterval;

  /// A driver of the page [evaluate] runs in.
  AgentWebPage(
    this.evaluate, {
    this.pollInterval = const Duration(milliseconds: 300),
  });

  static String _selector(String id) =>
      jsonEncode('[flt-semantics-identifier=${jsonEncode(id)}]');

  /// The ids on screen, in document order.
  Future<List<String>> ids() async {
    var value = await evaluate(
      "[...document.querySelectorAll('[flt-semantics-identifier]')]"
      ".map((e) => e.getAttribute('flt-semantics-identifier'))",
    );
    return (value as List?)?.cast<String>() ?? const [];
  }

  /// True when [id] is on screen.
  Future<bool> has(String id) async =>
      await evaluate('document.querySelector(${_selector(id)}) != null') ==
      true;

  /// Waits for [id] (all of [others] too), returns the ids on screen then.
  /// Throws a [TimeoutException] listing the ids on screen.
  Future<List<String>> waitFor(
    String id, {
    List<String> others = const [],
    Duration timeout = const Duration(seconds: 30),
  }) async {
    var stopwatch = Stopwatch()..start();
    var expected = [id, ...others];
    var onScreen = <String>[];
    while (true) {
      onScreen = await ids();
      if (expected.every(onScreen.contains)) {
        return onScreen;
      }
      if (stopwatch.elapsed > timeout) {
        var missing = expected.where((id) => !onScreen.contains(id));
        throw TimeoutException(
          'missing ${missing.join(', ')}; on screen: ${onScreen.join(', ')}',
          timeout,
        );
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  /// The text of [id] (its aria label, else its text content), null when
  /// it is not on screen.
  Future<String?> text(String id) async {
    var value = await evaluate(
      '(() => { var e = document.querySelector(${_selector(id)});'
      " return e ? (e.getAttribute('aria-label') || e.textContent || '')"
      ' : null; })()',
    );
    return (value as String?)?.trim();
  }

  /// Waits for [id] then taps it (a click on its semantics node: the
  /// Flutter tap action).
  Future<void> tap(
    String id, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await waitFor(id, timeout: timeout);
    await evaluate('document.querySelector(${_selector(id)}).click()');
  }

  /// The path of the page (`location.pathname`), with its fragment
  /// (`location.hash`) when the app uses hash urls.
  Future<String> location() async =>
      (await evaluate('location.pathname + location.hash') as String?) ?? '';

  /// Waits for [location] to match [pattern], returns it.
  Future<String> waitForLocation(
    Pattern pattern, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    var stopwatch = Stopwatch()..start();
    while (true) {
      var current = await location();
      if (pattern.allMatches(current).isNotEmpty) {
        return current;
      }
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException('location $current, expected $pattern', timeout);
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  /// The browser back button.
  Future<void> back() async {
    await evaluate('history.back()');
  }

  /// True when the app exposes its commands (opened with `?agent`).
  Future<bool> hasCommands() async =>
      await evaluate('typeof window.$agentBridgeName === "object"') == true;

  /// The descriptions of the commands of the app (`name`, `description`,
  /// `inputSchema`), through its js bridge (`?agent`).
  Future<List<Map<String, Object?>>> commands() async {
    var value = await evaluate('window.$agentBridgeName.commands()');
    return [
      for (var command in (value as List?) ?? const [])
        (command as Map).cast<String, Object?>(),
    ];
  }

  /// Runs the command [name] of the app with [args] through its js bridge,
  /// returns its result; throws an [AgentCommandException] with its error.
  Future<Object?> run(String name, [Map<String, Object?>? args]) async {
    var value = await evaluate(
      'window.$agentBridgeName.run(${jsonEncode(name)}, '
      '${jsonEncode(args ?? const <String, Object?>{})})',
      awaitPromise: true,
    );
    if (value is! Map) {
      throw AgentCommandException('$name: no result ($value)');
    }
    if (value['ok'] != true) {
      throw AgentCommandException('${value['error']}');
    }
    return value['result'];
  }
}
