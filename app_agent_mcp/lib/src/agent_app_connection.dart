import 'package:tekartik_app_agent/app_agent.dart';

/// A running app an agent talks to: its commands (`agentCommands` of
/// tekartik_app_agent), read and run through a channel (the VM service of a
/// debug run, the js bridge of a web page).
abstract class AgentAppConnection {
  /// What it is connected to, for the agent (`vm service ws://...`,
  /// `chrome page http://...`).
  String get description;

  /// The descriptions of the commands of the app (`name`, `description`,
  /// `inputSchema`), the ones registered now.
  Future<List<Map<String, Object?>>> commands();

  /// Runs the command [name] with [args]; a channel failure (the app gone)
  /// throws.
  Future<AgentCommandResult> run(String name, [Map<String, Object?>? args]);

  /// Disconnects (and stops what it started).
  Future<void> close();
}

/// The commands of this program ([registry], [agentCommands] by default),
/// in process: an MCP server serving commands of its own (a data server,
/// `AgentMcpServer` without its connect tools).
class AgentLocalConnection implements AgentAppConnection {
  /// The commands.
  final AgentCommands registry;

  @override
  final String description;

  /// The commands of [registry].
  AgentLocalConnection({AgentCommands? registry, this.description = 'local'})
    : registry = registry ?? agentCommands;

  @override
  Future<List<Map<String, Object?>>> commands() async => registry.describe();

  @override
  Future<AgentCommandResult> run(String name, [Map<String, Object?>? args]) =>
      registry.run(name, args);

  @override
  Future<void> close() async {}
}

/// The [AgentCommandResult] of its json (`{ok, result}` or `{ok, error}`).
AgentCommandResult agentCommandResultFromJson(Object? json) {
  if (json is! Map) {
    return AgentCommandResult.error('no result ($json)');
  }
  if (json['ok'] == true) {
    return AgentCommandResult.ok(json['result']);
  }
  return AgentCommandResult.error('${json['error']}');
}

/// The command descriptions of a json list.
List<Map<String, Object?>> agentCommandsFromJson(Object? json) => [
  for (var command in (json as List?) ?? const [])
    (command as Map).cast<String, Object?>(),
];
