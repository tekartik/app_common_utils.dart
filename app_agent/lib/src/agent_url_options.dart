/// The agent options a page url turns on, read from its query and, for a
/// hash url (`/#/home?agent`), from the query of its fragment.
///
/// - `?semantics`: the app builds its accessibility tree from the start (on
///   the web, the semantics DOM with its `flt-semantics-identifier` ids,
///   without the "enable accessibility" button);
/// - `?agent`: the same, and the app exposes its agent commands to the page
///   scripts.
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

  /// Options, all off by default.
  const AgentUrlOptions({this.semantics = false, this.agent = false});

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
    );
  }

  /// True when the app should build its accessibility tree from the start.
  bool get needsSemantics => semantics || agent;

  @override
  String toString() => 'AgentUrlOptions(semantics: $semantics, agent: $agent)';
}
