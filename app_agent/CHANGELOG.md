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
