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
