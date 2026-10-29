---
name: tekartik-app-agent-mcp
description: >-
  Use when an agent (Claude Code...) should drive a running app built with
  tekartik_app_agent / tekartik_app_agent_flutter through MCP, or when
  writing a tool that talks to such an app: tekartik_app_agent_mcp
  (AgentMcpServer, the stdio executable tekartik_app_agent_mcp, app_connect
  with a VM service uri or a web url with ?agent, the app commands as
  tools), AgentVmConnection (VM service extensions of a debug run),
  AgentChromeConnection (js bridge over the Chrome DevTools protocol,
  semantics ids, screenshot).
---

# MCP bridge to a running app (tekartik_app_agent_mcp)

## Guidelines

* The app side: commands registered in `agentCommands` (pure Dart
  `AgentCommand`s, Flutter `AgentCommandsScope`), exposed by `agentInit()`
  (tekartik_app_agent_flutter): the VM service extensions outside release
  builds, the js bridge with `?agent` on the web. A Dart program calls
  `agentVmRegister(agentCommands)` (tekartik_app_agent).
* Install: `dart install
  'tekartik_app_agent_mcp@{git: {url: https://github.com/tekartik/app_common_utils.dart, path: app_agent_mcp}}'`,
  then `claude mcp add app-agent -- tekartik_app_agent_mcp`. Without
  installing: `dart run tekartik_app_agent_mcp` from a package depending on
  it (the build messages of `dart run` stay off stdout, the MCP channel).
* Connect: `app_connect` with `vmService` (the uri `flutter run` prints,
  `http://127.0.0.1:port/token=/`, also its DevTools link or the `ws://`
  form, see `agentVmServiceWsUri`), or `open` (a url with `?agent`, a new
  headless Chrome with the WebGL flags Flutter needs; `headless: false` to
  watch), or `chrome` + `page` (a Chrome started with
  `--remote-debugging-port`).
* The commands of the app become tools of their own name (an app command
  named like an own tool, `app_*`, is only reachable by `app_run`). They are
  read again after each command (a fresh read, not one already running) and
  every `syncInterval` (2 s), the client notified (`tools/list_changed`): a
  project opened brings its commands a moment after the command that opened
  it; wait for the tool (`app_commands` lists them now).
* Errors come back as tool errors with the message only: the
  `AgentCommandException` message of the app, `not connected to an app:
  app_connect first`, `a web page only (...)`, a timeout saying what to
  check (`agentInit`, `?agent`).
* A hot restart changes the isolate: the VM connection finds the isolate
  with the extensions again on the next call.
* Debug runs without a screen: `xvfb-run -a flutter run -d linux --machine`
  and the `app.debugPort` event's `wsUri`.
* Tests: the VM channel against a Dart program started with
  `--enable-vm-service=0` (it prints `Dart VM service is listening on
  http://...`); the Chrome channel on a `data:` url page defining
  `window.tekartikAgent`; the server in memory with a dart_mcp `MCPClient`
  on a `StreamChannelController<String>`.

## Example

```dart
import 'package:tekartik_app_agent_mcp/app_agent_mcp.dart';

Future<void> main() async {
  var connection = await AgentVmConnection.connect(
    'http://127.0.0.1:8181/abc=/',
  );
  for (var command in await connection.commands()) {
    print(command['name']);
  }
  var result = await connection.run('persons', {'search': 'ada'});
  print(result.ok ? result.result : result.error);
  await connection.close();
}
```
