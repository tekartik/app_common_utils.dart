## 0.4.0

- `AgentKey`: the key a release build asks (`?agent=<key>`), held as its
  SHA-256 hash (`AgentKey.hashed`, `hashOf`, `generate`), never shown.
- `AgentUrlOptions.agentAllowed(release:, releaseKey:)`: `?agent` lets an
  agent in (the default), a release build of an app with a key asks it,
  `?agent=<key>` (read and checked only when the url has `?agent`).
- `package:tekartik_app_agent/agent_constants_io.dart`: the agent constants
  of a project (`AgentKeyApp`, `agentConstantsGenerate` writing
  `lib/src/agent_constants.dart` or dumping it, the keys kept, their links
  documented, the constants `@internal`).

## 0.3.0

- `agentVmRegister` (moved from tekartik_app_agent_flutter):
  `ext.tekartik.agent.commands` / `ext.tekartik.agent.run`
  (`agentVmCommandsExtension`, `agentVmRunExtension`), usable from a Dart
  program too.

## 0.2.0

- `AgentCommand`, `AgentCommands` (`agentCommands`, scoped registrations),
  `AgentCommandResult`, `AgentCommandException`, `AgentSchema`: the commands
  of an app, json schema arguments (the MCP tool shape).
- `AgentWebPage`: `commands()`, `run(name, args)`, `hasCommands()` through
  the js bridge (`window.tekartikAgent`, `agentBridgeName`); `AgentEvaluate`
  takes `awaitPromise`.

## 0.1.0

- `AgentUrlOptions` (`?semantics`, `?agent`) and `AgentWebPage`, a driver of
  the Flutter web semantics ids.
