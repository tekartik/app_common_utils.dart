/// An MCP server (stdio) bridging an agent client (Claude Code...) to the
/// commands of a running app (`agentCommands` of tekartik_app_agent):
///
/// - [AgentMcpServer]: the tools (`app_connect`, `app_run`, the commands of
///   the app as tools of their own, kept in sync, `app_ids`, `app_tap`,
///   `app_screenshot` on a web page);
/// - [AgentVmConnection]: a debug or profile run, through its VM service
///   extensions;
/// - [AgentChromeConnection]: a web page opened with `?agent` (release
///   builds included), through its js bridge over the Chrome DevTools
///   protocol, in a Chrome it starts or a running one;
/// - [AgentLocalConnection]: commands of the program itself (a data server
///   on [AgentMcpServer] without its connect tools).
library;

export 'src/agent_app_connection.dart'
    show AgentAppConnection, AgentLocalConnection;
export 'src/agent_chrome_connection.dart'
    show AgentChromeConnection, agentChromeExecutable, agentChromePages;
export 'src/agent_mcp_server.dart' show AgentMcpServer;
export 'src/agent_vm_connection.dart'
    show AgentVmConnection, agentVmServiceWsUri;
