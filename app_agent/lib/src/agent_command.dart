import 'dart:async';
import 'dart:convert';

/// Runs a command with its json [args], returns a json value (map, list,
/// string, number, bool or null).
typedef AgentCommandRun = FutureOr<Object?> Function(Map<String, Object?> args);

/// A command of an app an agent can call: its [name], what it does
/// ([description]), its arguments ([inputSchema], a json schema object, the
/// MCP tool shape) and how it runs.
class AgentCommand {
  /// The name (`events`, `set_favorite`): letters, digits and `_`.
  final String name;

  /// What it does and returns, for the agent.
  final String description;

  /// The json schema of its arguments, an object (see [AgentSchema]).
  final Map<String, Object?> inputSchema;

  /// Runs it.
  final AgentCommandRun run;

  /// A command.
  AgentCommand({
    required this.name,
    required this.description,
    Map<String, Object?>? inputSchema,
    required this.run,
  }) : inputSchema = inputSchema ?? AgentSchema.object({});

  /// Its description as json: `name`, `description`, `inputSchema`.
  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
  };

  @override
  String toString() => 'AgentCommand($name)';
}

/// Thrown by a command for an error the agent should read (a missing
/// record, an invalid value): its [message] is the result error.
class AgentCommandException implements Exception {
  /// The message.
  final String message;

  /// An error of a command.
  AgentCommandException(this.message);

  @override
  String toString() => 'AgentCommandException: $message';
}

/// The result of a command run: [ok] and its [result], or its [error].
class AgentCommandResult {
  /// True when the command ran.
  final bool ok;

  /// The json result, when [ok].
  final Object? result;

  /// The error, when not [ok].
  final String? error;

  /// A success.
  const AgentCommandResult.ok(this.result) : ok = true, error = null;

  /// A failure.
  const AgentCommandResult.error(String this.error) : ok = false, result = null;

  /// `{ok: true, result: ...}` or `{ok: false, error: ...}`.
  Map<String, Object?> toJson() =>
      ok ? {'ok': true, 'result': result} : {'ok': false, 'error': error};

  @override
  String toString() => 'AgentCommandResult(${jsonEncode(toJson())})';
}

/// Builders of the json schemas of command arguments.
abstract final class AgentSchema {
  /// An object of [properties], [required] ones.
  static Map<String, Object?> object(
    Map<String, Map<String, Object?>> properties, {
    List<String> required = const [],
    String? description,
  }) => {
    'type': 'object',
    'description': ?description,
    'properties': properties,
    if (required.isNotEmpty) 'required': required,
  };

  /// A string, one of [values] when given.
  static Map<String, Object?> string(
    String description, {
    List<String>? values,
  }) => {'type': 'string', 'description': description, 'enum': ?values};

  /// A boolean.
  static Map<String, Object?> boolean(String description) => {
    'type': 'boolean',
    'description': description,
  };

  /// An integer.
  static Map<String, Object?> integer(String description) => {
    'type': 'integer',
    'description': description,
  };

  /// Any object (a record, its fields).
  static Map<String, Object?> anyObject(String description) => {
    'type': 'object',
    'description': description,
  };
}

/// A set of commands added together, removed together ([remove]).
class AgentCommandsRegistration {
  final AgentCommands _commands;

  /// The commands added.
  final List<AgentCommand> commands;

  AgentCommandsRegistration._(this._commands, this.commands);

  /// Removes them (the commands of the same name registered before are
  /// back).
  void remove() => _commands._registrations.remove(this);
}

/// The commands of an app, as the parts of the app register them
/// ([add], removed with [AgentCommandsRegistration.remove]): a later
/// registration hides a command of the same name, until removed.
///
/// [agentCommands] is the one of the app, the one the channels (web js
/// bridge, VM service extension) expose.
class AgentCommands {
  final _registrations = <AgentCommandsRegistration>[];

  /// Adds [commands], returns their registration.
  AgentCommandsRegistration add(List<AgentCommand> commands) {
    var registration = AgentCommandsRegistration._(this, commands);
    _registrations.add(registration);
    return registration;
  }

  /// The commands, by name (the latest registration of a name).
  Map<String, AgentCommand> get byName => {
    for (var registration in _registrations)
      for (var command in registration.commands) command.name: command,
  };

  /// The descriptions of the commands, sorted by name (see
  /// [AgentCommand.toJson]).
  List<Map<String, Object?>> describe() {
    var commands = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return [for (var command in commands) command.toJson()];
  }

  /// Runs the command [name] with [args]: checks the required arguments,
  /// catches its errors ([AgentCommandException] gives its message) and
  /// checks that its result is json.
  Future<AgentCommandResult> run(
    String name, [
    Map<String, Object?>? args,
  ]) async {
    var commands = byName;
    var command = commands[name];
    if (command == null) {
      var known = commands.keys.toList()..sort();
      return AgentCommandResult.error(
        'unknown command $name, known: ${known.join(', ')}',
      );
    }
    args ??= const {};
    var required = command.inputSchema['required'];
    if (required is List) {
      var missing = required.where((name) => args![name] == null).toList();
      if (missing.isNotEmpty) {
        return AgentCommandResult.error('$name: missing ${missing.join(', ')}');
      }
    }
    Object? result;
    try {
      result = await command.run(args);
    } on AgentCommandException catch (e) {
      return AgentCommandResult.error(e.message);
    } catch (e) {
      return AgentCommandResult.error('$name failed: $e');
    }
    try {
      jsonEncode(result);
    } catch (e) {
      return AgentCommandResult.error('$name: result is not json ($e)');
    }
    return AgentCommandResult.ok(result);
  }
}

/// The commands of the app, exposed by `agentInit` of
/// tekartik_app_agent_flutter (the web js bridge with `?agent`, a VM service
/// extension in debug).
final agentCommands = AgentCommands();
