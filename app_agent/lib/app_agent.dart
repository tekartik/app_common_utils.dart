/// Helpers for the apps an agent (an LLM, a test tool) drives:
///
/// - [AgentUrlOptions]: the `?semantics` and `?agent` options of a page url;
/// - [AgentWebPage]: a driver of the Flutter web semantics ids
///   (`flt-semantics-identifier`) through a page evaluate function (Chrome
///   DevTools protocol, Playwright, a browser extension).
library;

export 'src/agent_url_options.dart' show AgentUrlOptions;
export 'src/agent_web_page.dart' show AgentEvaluate, AgentWebPage;
