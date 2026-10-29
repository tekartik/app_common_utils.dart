import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/server.dart';
import 'package:tekartik_app_agent/app_agent.dart';

import 'agent_app_connection.dart';
import 'agent_chrome_connection.dart';
import 'agent_vm_connection.dart';

const _instructions =
    'Drives a running app built with tekartik_app_agent by its commands. '
    'First app_connect: the VM service uri a debug run prints (flutter run, '
    'dart run --enable-vm-service), or a web build url with ?agent opened '
    'in a headless Chrome (open), or a page of a Chrome started with '
    '--remote-debugging-port (chrome). The commands of the app then appear '
    'as tools of their own name (and run with app_run); they change with '
    'the screens of the app (opening a record or a project adds some): the '
    'tools follow after each command, app_commands lists them again. In a '
    'web page, app_ids, app_tap and app_screenshot show and drive the '
    'screen by its semantics ids.';

/// The names of the tools of the server, never an app command.
const _ownTools = {
  'app_connect',
  'app_disconnect',
  'app_commands',
  'app_run',
  'app_ids',
  'app_tap',
  'app_screenshot',
};

CallToolResult _text(String text, {bool error = false}) => CallToolResult(
  content: [TextContent(text: text)],
  isError: error ? true : null,
);

CallToolResult _json(Object? value) => _text(jsonEncode(value));

CallToolResult _commandResult(AgentCommandResult result) => result.ok
    ? _json(result.result)
    : _text(result.error ?? 'failed', error: true);

/// An MCP server (tools) bridging an agent client (Claude Code...) to the
/// commands of a running app ([AgentAppConnection]: [AgentVmConnection],
/// [AgentChromeConnection]): `app_connect`, `app_disconnect`,
/// `app_commands`, `app_run`, the web page tools (`app_ids`, `app_tap`,
/// `app_screenshot`), and each command of the app as a tool of its name,
/// kept in sync with the app (tool list changes notified).
base class AgentMcpServer extends MCPServer with ToolsSupport {
  AgentAppConnection? _connection;

  /// The commands registered as tools, by name: their description json.
  final _appTools = <String, String>{};

  /// How often the tools follow the commands of the app while connected
  /// (also after each command), null for after the commands only.
  final Duration? syncInterval;

  /// The more arguments of a Chrome `app_connect` starts (`--no-sandbox`
  /// on a CI runner).
  final List<String> chromeArguments;

  Timer? _syncTimer;
  Future<List<Map<String, Object?>>>? _syncing;

  /// The server, on [channel] (`stdioChannel` of dart_mcp for a stdio
  /// server), connected to [connection] when given.
  ///
  /// Without [connectTools] the server only serves [connection] (an
  /// [AgentLocalConnection], say): no `app_connect`, `app_disconnect` nor
  /// web page tools. [implementation] and [instructions] describe a server
  /// of its own (a data server).
  AgentMcpServer(
    super.channel, {
    AgentAppConnection? connection,
    bool connectTools = true,
    Implementation? implementation,
    String? instructions,
    this.syncInterval = const Duration(seconds: 2),
    this.chromeArguments = const [],
    super.protocolLogSink,
  }) : super.fromStreamChannel(
         implementation:
             implementation ??
             Implementation(name: 'tekartik_app_agent_mcp', version: '0.2.0'),
         instructions: instructions ?? _instructions,
       ) {
    if (connectTools) {
      _registerConnectTools();
    }
    _registerCommandTools();
    if (connectTools) {
      _registerWebTools();
    }
    if (connection != null) {
      _attach(connection);
      unawaited(_syncTools().then((_) {}, onError: (_) {}));
    }
  }

  void _registerConnectTools() {
    _tool(
      Tool(
        name: 'app_connect',
        description:
            'Connects to a running app (one of): vmService, the VM service '
            'uri of a debug or profile run (http://127.0.0.1:port/token=/ '
            'as printed by flutter run); open, a url to open in a new '
            'Chrome (add ?agent for the commands), headless unless headless '
            'is false; chrome, the debugging endpoint of a running Chrome '
            '(http://127.0.0.1:9222) with page, a part of the page url. '
            'Returns the commands of the app, now tools too.',
        inputSchema: Schema.object(
          properties: {
            'vmService': Schema.string(description: 'A VM service uri'),
            'open': Schema.string(description: 'A url to open in Chrome'),
            'headless': Schema.bool(description: 'false to show the Chrome'),
            'width': Schema.int(description: 'The window width (1280)'),
            'height': Schema.int(description: 'The window height (800)'),
            'chrome': Schema.string(description: 'A Chrome debugging endpoint'),
            'page': Schema.string(description: 'A part of the page url'),
          },
        ),
      ),
      _connect,
    );
    _tool(
      Tool(
        name: 'app_disconnect',
        description: 'Disconnects from the app (closes a Chrome it opened).',
        inputSchema: Schema.object(),
      ),
      (_) async {
        await disconnect();
        return _text('disconnected');
      },
    );
  }

  void _registerCommandTools() {
    _tool(
      Tool(
        name: 'app_commands',
        description:
            'The app connected and its commands now (name, description, '
            'inputSchema), the tools updated.',
        inputSchema: Schema.object(),
      ),
      (_) async {
        var connection = _connected();
        var commands = await _syncTools();
        return _json({
          'connection': connection.description,
          'commands': commands,
        });
      },
    );
    _tool(
      Tool(
        name: 'app_run',
        description:
            'Runs the command [name] of the app with [args] (an object), '
            'returns its json result.',
        inputSchema: Schema.object(
          properties: {
            'name': Schema.string(description: 'The command'),
            'args': Schema.object(description: 'Its arguments'),
          },
          required: ['name'],
        ),
      ),
      (request) => _run(
        request.arguments!['name'] as String,
        (request.arguments!['args'] as Map?)?.cast<String, Object?>(),
      ),
    );
  }

  void _registerWebTools() {
    _tool(
      Tool(
        name: 'app_ids',
        description:
            'Web page: the semantics ids on screen (flt-semantics-identifier, '
            'with ?agent or ?semantics), in document order.',
        inputSchema: Schema.object(),
      ),
      (_) async => _json(await _chrome().page.ids()),
    );
    _tool(
      Tool(
        name: 'app_tap',
        description:
            'Web page: waits for the semantics [id] (10 s at most) and taps '
            'it. Returns the ids on screen after.',
        inputSchema: Schema.object(
          properties: {'id': Schema.string(description: 'A semantics id')},
          required: ['id'],
        ),
      ),
      (request) async {
        var page = _chrome().page;
        await page.tap(
          request.arguments!['id'] as String,
          timeout: const Duration(seconds: 10),
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        unawaited(_syncTools().then((_) {}, onError: (_) {}));
        return _json(await page.ids());
      },
    );
    _tool(
      Tool(
        name: 'app_screenshot',
        description: 'Web page: a png screenshot of the page.',
        inputSchema: Schema.object(),
      ),
      (_) async => CallToolResult(
        content: [
          ImageContent(
            data: await _chrome().screenshot(),
            mimeType: 'image/png',
          ),
        ],
      ),
    );
  }

  void _attach(AgentAppConnection connection) {
    _connection = connection;
    if (syncInterval case var interval?) {
      _syncTimer = Timer.periodic(interval, (_) {
        // The app may be busy or gone: the next command tells.
        _syncTools().then((_) {}, onError: (_) {});
      });
    }
  }

  /// Registers one of the own tools.
  void _tool(
    Tool tool,
    FutureOr<CallToolResult> Function(CallToolRequest request) impl,
  ) => registerTool(tool, (request) => _guard(() async => impl(request)));

  /// [run], an error as its message.
  Future<CallToolResult> _guard(Future<CallToolResult> Function() run) async {
    try {
      return await run();
    } catch (e) {
      var message = switch (e) {
        StateError() => e.message,
        TimeoutException() => '${e.message}',
        AgentCommandException() => e.message,
        _ => '$e',
      };
      return _text(message, error: true);
    }
  }

  /// The app connected, null when none.
  AgentAppConnection? get connection => _connection;

  AgentAppConnection _connected() =>
      _connection ??
      (throw StateError('not connected to an app: app_connect first'));

  AgentChromeConnection _chrome() => switch (_connected()) {
    AgentChromeConnection chrome => chrome,
    _ => throw StateError('a web page only (app_connect with open or chrome)'),
  };

  Future<CallToolResult> _connect(CallToolRequest request) async {
    var args = request.arguments ?? const <String, Object?>{};
    String? string(String name) {
      var value = args[name];
      return value is String && value.isNotEmpty ? value : null;
    }

    var vmService = string('vmService');
    var open = string('open');
    var chrome = string('chrome');
    if ([vmService, open, chrome].nonNulls.length != 1) {
      return _text('one of vmService, open, chrome expected', error: true);
    }
    await disconnect();
    AgentAppConnection connection;
    if (vmService != null) {
      connection = await AgentVmConnection.connect(vmService);
    } else if (open != null) {
      connection = await AgentChromeConnection.launch(
        Uri.parse(open),
        headless: args['headless'] != false,
        width: (args['width'] as int?) ?? 1280,
        height: (args['height'] as int?) ?? 800,
        arguments: chromeArguments,
      );
    } else {
      connection = await AgentChromeConnection.connect(
        Uri.parse(chrome!),
        page: string('page'),
      );
    }
    _attach(connection);
    var commands = await _syncTools();
    return _json({
      'connection': connection.description,
      'commands': [for (var command in commands) command['name']],
    });
  }

  /// Disconnects from the app, its tools removed.
  Future<void> disconnect() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    var connection = _connection;
    _connection = null;
    for (var name in _appTools.keys.toList()) {
      unregisterTool(name);
    }
    _appTools.clear();
    await connection?.close();
  }

  Future<CallToolResult> _run(String name, Map<String, Object?>? args) async {
    var result = await _connected().run(name, args);
    // A command may open a screen bringing other commands.
    try {
      await _syncTools(fresh: true);
    } catch (_) {
      // The page may be loading.
    }
    return _commandResult(result);
  }

  /// Reads the commands of the app and registers them as tools (the ones
  /// gone removed, the changed ones replaced), one sync at a time. Returns
  /// them. [fresh]: a sync started after now (not one running, which may
  /// have read the commands before a change).
  Future<List<Map<String, Object?>>> _syncTools({bool fresh = false}) async {
    if (fresh && _syncing != null) {
      try {
        await _syncing;
      } catch (_) {}
    }
    return _syncing ??= _doSyncTools().whenComplete(() => _syncing = null);
  }

  Future<List<Map<String, Object?>>> _doSyncTools() async {
    var connection = _connected();
    var commands = await connection.commands();
    if (!identical(connection, _connection)) {
      // Disconnected meanwhile.
      return commands;
    }
    var seen = <String>{};
    for (var command in commands) {
      var name = command['name'];
      if (name is! String || _ownTools.contains(name)) {
        continue;
      }
      seen.add(name);
      var json = jsonEncode(command);
      if (_appTools[name] == json) {
        continue;
      }
      if (_appTools.containsKey(name)) {
        unregisterTool(name);
      }
      _appTools[name] = json;
      registerTool(
        Tool(
          name: name,
          description: '${command['description'] ?? ''}',
          inputSchema: ObjectSchema.fromMap(
            ((command['inputSchema'] as Map?) ?? {'type': 'object'})
                .cast<String, Object?>(),
          ),
        ),
        (request) => _guard(() => _run(name, request.arguments)),
        // The app checks its arguments.
        validateArguments: false,
      );
    }
    for (var name in _appTools.keys.toList()) {
      if (!seen.contains(name)) {
        _appTools.remove(name);
        unregisterTool(name);
      }
    }
    return commands;
  }

  @override
  Future<void> shutdown() async {
    await disconnect();
    await super.shutdown();
  }
}
