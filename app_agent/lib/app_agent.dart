/// Helpers for the apps an agent (an LLM, a test tool) drives:
///
/// - [AgentUrlOptions]: the `?semantics` and `?agent` options of a page url,
///   [AgentKey]: the key a release build asks (`?agent=<key>`), held as its
///   hash (the generator of the agent constants of a project is
///   `package:tekartik_app_agent/agent_constants_io.dart`);
/// - [AgentWebPage]: a driver of the Flutter web semantics ids
///   (`flt-semantics-identifier`) and of the app commands (its js bridge)
///   through a page evaluate function (Chrome DevTools protocol, Playwright,
///   a browser extension).
/// - [AgentCommand], [AgentCommands] ([agentCommands], the ones of the
///   app), [AgentSchema]: what an app lets an agent do;
/// - [agentVmRegister]: the commands as VM service extensions (a debug run).
library;

export 'src/agent_command.dart'
    show
        AgentCommand,
        AgentCommandException,
        AgentCommandResult,
        AgentCommandRun,
        AgentCommands,
        AgentCommandsRegistration,
        AgentSchema,
        agentCommands;
export 'src/agent_key.dart' show AgentKey;
export 'src/agent_url_options.dart' show AgentUrlOptions;
export 'src/agent_vm.dart'
    show agentVmCommandsExtension, agentVmRegister, agentVmRunExtension;
export 'src/agent_web_page.dart'
    show AgentEvaluate, AgentWebPage, agentBridgeName;
