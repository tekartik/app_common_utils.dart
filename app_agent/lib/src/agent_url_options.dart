import 'agent_key.dart';

/// The agent options a page url turns on, read from its query and, for a
/// hash url (`/#/home?agent`), from the query of its fragment.
///
/// - `?semantics`: the app builds its accessibility tree from the start (on
///   the web, the semantics DOM with its `flt-semantics-identifier` ids,
///   without the "enable accessibility" button);
/// - `?agent`: the same, and the app exposes its agent commands to the page
///   scripts; a release build of an app with a key asks it
///   (`?agent=<key>`, see [agentAllowed] and [AgentKey]).
///
/// A parameter is on when present, empty or with any value but `0`,
/// `false`, `no` or `off`.
class AgentUrlOptions {
  /// The semantics query parameter.
  static const semanticsParameter = 'semantics';

  /// The agent query parameter.
  static const agentParameter = 'agent';

  /// `?semantics` is on.
  final bool semantics;

  /// `?agent` is on.
  final bool agent;

  /// The value of `?agent`, checked against the key of a release build
  /// only ([agentAllowed]), never shown.
  final String? _agentValue;

  /// Options, all off by default; `agentValue`: the value of `?agent`.
  const AgentUrlOptions({
    this.semantics = false,
    this.agent = false,
    this._agentValue,
  });

  /// The options of [uri] (`Uri.base` in an app).
  factory AgentUrlOptions.fromUri(Uri uri) {
    var parameters = <String, String>{...uri.queryParameters};
    var fragment = uri.fragment;
    var queryStart = fragment.indexOf('?');
    if (queryStart >= 0) {
      try {
        parameters.addAll(
          Uri.splitQueryString(fragment.substring(queryStart + 1)),
        );
      } on FormatException {
        // An invalid fragment query: ignored.
      }
    }
    bool on(String name) {
      var value = parameters[name];
      return value != null &&
          !const ['0', 'false', 'no', 'off'].contains(value.toLowerCase());
    }

    return AgentUrlOptions(
      semantics: on(semanticsParameter),
      agent: on(agentParameter),
      agentValue: parameters[agentParameter],
    );
  }

  /// True when the app should build its accessibility tree from the start
  /// (with [agent], once [agentAllowed]).
  bool get needsSemantics => semantics || agent;

  /// Whether an agent is let in: [agent] on and, in a [release] build of an
  /// app with a key ([releaseKey] giving one), its value that key
  /// (`?agent=<key>`); without a key, `?agent` is enough. The key is read
  /// and checked only when [agent] is on.
  bool agentAllowed({required bool release, AgentKey? Function()? releaseKey}) {
    if (!agent) {
      return false;
    }
    if (!release) {
      return true;
    }
    var key = releaseKey?.call();
    // No key for the app: ?agent is enough.
    return key == null || key.matches(_agentValue);
  }

  @override
  String toString() => 'AgentUrlOptions(semantics: $semantics, agent: $agent)';
}
