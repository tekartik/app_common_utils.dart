## 0.2.0

- `AgentLocalConnection`: the commands of the program itself; `AgentMcpServer`
  takes `connectTools` (false: no connect nor web page tools),
  `implementation` and `instructions`, for a server of its own commands (a
  data server).
- The connect messages and tool descriptions mention `?agent=<key>`, what a
  release build asks.

## 0.1.0

- `AgentMcpServer` (dart_mcp, stdio executable `tekartik_app_agent_mcp`):
  `app_connect`, `app_disconnect`, `app_commands`, `app_run`, the commands
  of the app as tools of their own name (kept in sync, tool list changes
  notified), `app_ids`, `app_tap`, `app_screenshot` on a web page.
- `AgentVmConnection`: a debug or profile run through its VM service
  extensions (`agentVmRegister`), found again after a hot restart.
- `AgentChromeConnection`: a web page opened with `?agent` through its js
  bridge over the Chrome DevTools protocol, in a Chrome it starts
  (headless) or a running one (`--remote-debugging-port`).
