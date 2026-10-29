import 'dart:convert';
import 'dart:developer';

import 'agent_command.dart';

/// The VM service extension listing the commands.
const agentVmCommandsExtension = 'ext.tekartik.agent.commands';

/// The VM service extension running a command (`name`, `args` as json).
const agentVmRunExtension = 'ext.tekartik.agent.run';

var _registered = false;

/// Registers the VM service extensions of [commands] (once):
/// [agentVmCommandsExtension] (`{commands: [...]}`) and [agentVmRunExtension]
/// (`name`, `args` as json: `{ok, result}` or `{ok, error}`), reachable from
/// the Dart tooling of a debug or profile run (tekartik_app_agent_mcp, DTD,
/// `callServiceExtension`). `agentInit` of tekartik_app_agent_flutter calls
/// it; a Dart program (a CLI, a server) can too.
void agentVmRegister(AgentCommands commands) {
  if (_registered) {
    return;
  }
  _registered = true;
  registerExtension(agentVmCommandsExtension, (method, parameters) async {
    return ServiceExtensionResponse.result(
      jsonEncode({'commands': commands.describe()}),
    );
  });
  registerExtension(agentVmRunExtension, (method, parameters) async {
    var name = parameters['name'];
    if (name == null) {
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.invalidParams,
        'missing name',
      );
    }
    Map<String, Object?>? args;
    var argsText = parameters['args'];
    if (argsText != null && argsText.isNotEmpty) {
      args = (jsonDecode(argsText) as Map).cast<String, Object?>();
    }
    var result = await commands.run(name, args);
    return ServiceExtensionResponse.result(jsonEncode(result.toJson()));
  });
}
