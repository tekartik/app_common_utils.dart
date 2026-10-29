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

- `AgentKey`: the key a release build of an app given one asks before
  exposing its commands (`?agent=<key>`), see [Agent keys](#agent-keys).
- `agentVmRegister(commands)`: the commands as the VM service extensions
  `ext.tekartik.agent.commands` / `ext.tekartik.agent.run` of a debug run,
  what `tekartik_app_agent_mcp` (an MCP server) and other Dart tools call.

The MCP server is [tekartik_app_agent_mcp](../app_agent_mcp). The Flutter
side (the `AgentId` widget, the semantics built from the url options) is
`tekartik_app_agent_flutter` in
[app_flutter_utils.dart](https://github.com/tekartik/app_flutter_utils.dart).

## Setup

```yaml
  tekartik_app_agent:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_agent
```

## Agent keys

`?agent` lets an agent in by default. An app given a key
(`agentInit(releaseKey:)` of tekartik_app_agent_flutter) exposes its
commands in a release build only when opened with `?agent=<key>`. The app
holds only the hash of its key (`AgentKey.hashed`), checked only when the
url has `?agent` (`AgentUrlOptions.agentAllowed(release:, releaseKey:)`);
`?agent` alone stays enough in a debug build.

The keys of a project are generated in its private common package by a
tool calling `agentConstantsGenerate`
(`package:tekartik_app_agent/agent_constants_io.dart`): it writes
`lib/src/agent_constants.dart` (or prints it with `dump: true`), for each
app its `<app>AgentKey` (the hash, for the app) and `<app>AgentKeyText`
(the key, for the tools only), both `@internal`, the links
(`<url>?agent=<key>`) in their documentation. The keys are kept from one
run to the next, `renew: true` makes new ones.

```dart
// tool/agent_constants.dart of the private common package.
import 'package:tekartik_app_agent/agent_constants_io.dart';

Future<void> main(List<String> args) => agentConstantsGenerate([
  AgentKeyApp(
    name: 'orga',
    title: 'Festen Orga',
    urls: ['https://orga.example.com/'],
  ),
], dump: args.contains('--dump'), renew: args.contains('--renew'));
```

An app passes its key to `agentInit`, each internal use explicit:

```dart
// ignore: implementation_imports
import 'package:my_common_prv/src/agent_constants.dart';

void main() {
  // ignore: invalid_use_of_internal_member
  agentInit(releaseKey: orgaAgentKey);
}
```
