# tekartik_app_agent_mcp

An MCP server (stdio) that lets an agent client (Claude Code, Claude
desktop...) drive a running app by its commands: the `agentCommands` of
[tekartik_app_agent](../app_agent) that the app registers (in Flutter with
`agentInit` and `AgentCommandsScope` of `tekartik_app_agent_flutter`).

Two channels, the same commands behind each:

- **VM service** (`AgentVmConnection`): a debug or profile run (`flutter
  run`, `dart run --enable-vm-service`), through the VM service extensions
  `ext.tekartik.agent.commands` / `ext.tekartik.agent.run`
  (`agentVmRegister`, called by `agentInit` outside release builds).
- **Web page** (`AgentChromeConnection`): a web build opened with `?agent`
  (release builds included), through its js bridge `window.tekartikAgent`
  over the Chrome DevTools protocol, in a Chrome the server starts
  (headless by default) or a running Chrome started with
  `--remote-debugging-port`. Also the semantics ids of the screen and a
  screenshot.

## Tools

| Tool | What it does |
|---|---|
| `app_connect` | `vmService` (the uri `flutter run` prints), or `open` (a url, `?agent`, in a new Chrome; `headless`, `width`, `height`), or `chrome` (`http://127.0.0.1:9222`) with `page` (a part of its url) |
| `app_disconnect` | Disconnects, closes a Chrome it started |
| `app_commands` | The commands of the app now (name, description, input schema) |
| `app_run` | Runs a command: `name`, `args` |
| `<command>` | Each command of the app, a tool of its name, kept in sync with the app (after each command and every 2 s, the client notified of the tool list change) |
| `app_ids`, `app_tap`, `app_screenshot` | Web page: the semantics ids on screen, tap one, a png screenshot |

## Setup

Install the executable (compiled, on the PATH):

```sh
dart install 'tekartik_app_agent_mcp@{git: {url: https://github.com/tekartik/app_common_utils.dart, path: app_agent_mcp}}'
```

Add it to Claude Code:

```sh
claude mcp add app-agent -- tekartik_app_agent_mcp
```

Or, without installing, from a package depending on it:

```json
{
  "mcpServers": {
    "app-agent": {
      "command": "sh",
      "args": ["-c", "cd packages/my_support && exec dart run tekartik_app_agent_mcp"]
    }
  }
}
```

Options: `--vm-service <uri>`, `--open <url>` (`--no-headless`), `--chrome
<url>` (`--page <part>`) connect at start; otherwise the agent calls
`app_connect`.

## Use

1. Run the app: `flutter run -d linux` (note the VM service uri it prints)
   or serve a web build and give its url with `?agent`.
2. In the agent: `app_connect` with `vmService` or `open`.
3. Call the commands as tools (`festivals`, `open_festival`, `persons`...);
   new screens bring new commands (a project opened, a record shown): the
   tools follow.

## In code

```dart
import 'dart:io';

import 'package:dart_mcp/stdio.dart';
import 'package:tekartik_app_agent_mcp/app_agent_mcp.dart';

Future<void> main() async {
  var connection = await AgentChromeConnection.launch(
    Uri.parse('http://localhost:8080/?agent'),
  );
  print(await connection.commands());
  print((await connection.run('festivals')).toJson());
  await connection.close();

  // Or serve them over stdio.
  var server = AgentMcpServer(stdioChannel(input: stdin, output: stdout));
  await server.done;
}
```
