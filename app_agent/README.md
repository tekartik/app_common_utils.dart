# tekartik_app_agent

Helpers for the apps an agent (an LLM, a test tool) drives, pure Dart:

- `AgentUrlOptions.fromUri(Uri.base)`: the `?semantics` and `?agent`
  options of a page url (query, or the query of a hash url fragment).
  `?semantics` asks the app to build its accessibility tree from the start;
  `?agent` too, and to expose its agent commands.
- `AgentCommand`, `AgentCommands`: what an app lets an agent do, named
  commands with json schema arguments (`AgentSchema`, the MCP tool shape)
  returning json. `agentCommands` is the registry of the app; parts of the
  app add theirs (`add`, removed with the registration), a later one hiding
  a command of the same name. `run(name, args)` checks the required
  arguments and gives `{ok, result}` or `{ok, error}`.
- `AgentWebPage(evaluate)`: drives a Flutter web app by its semantics ids
  (the `flt-semantics-identifier` attributes set by `Semantics(identifier:)`,
  `AgentId` of `tekartik_app_agent_flutter`) through any page evaluate
  function (Chrome DevTools protocol, Playwright): `ids`, `has`, `waitFor`,
  `text`, `tap`, `location`, `waitForLocation`, `back`; and its commands
  through the js bridge of an app opened with `?agent`
  (`window.tekartikAgent`): `commands`, `run`.

The Flutter side (the `AgentId` widget, the semantics built from the url
options) is `tekartik_app_agent_flutter` in
[app_flutter_utils.dart](https://github.com/tekartik/app_flutter_utils.dart).

## Setup

```yaml
  tekartik_app_agent:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_agent
```
