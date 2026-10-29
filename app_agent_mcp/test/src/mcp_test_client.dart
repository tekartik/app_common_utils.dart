import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:tekartik_app_agent_mcp/app_agent_mcp.dart';

/// An [AgentMcpServer] and a client connected to it in memory.
class McpTestClient {
  /// The server.
  late final AgentMcpServer server;

  /// The client side of the connection.
  late final ServerConnection connection;

  final _tools = <String>[];

  McpTestClient._();

  /// Starts both ([newServer] creates the server, a default one when
  /// null), the client initialized.
  static Future<McpTestClient> start({
    AgentMcpServer Function(StreamChannel<String> channel)? newServer,
  }) async {
    var client = McpTestClient._();
    var channel = StreamChannelController<String>();
    client.server =
        newServer?.call(channel.foreign) ??
        AgentMcpServer(
          channel.foreign,
          // The CI runners may refuse the Chrome sandbox.
          chromeArguments: [
            if (Platform.environment['CI'] == 'true') '--no-sandbox',
          ],
        );
    var mcpClient = MCPClient(Implementation(name: 'test', version: '0.0.0'));
    client.connection = mcpClient.connectServer(channel.local);
    await client.connection.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: mcpClient.capabilities,
        clientInfo: mcpClient.implementation,
      ),
    );
    client.connection.notifyInitialized();
    return client;
  }

  /// The names of the tools now.
  Future<List<String>> tools() async {
    var result = await connection.listTools(ListToolsRequest());
    _tools
      ..clear()
      ..addAll(result.tools.map((tool) => tool.name));
    return _tools;
  }

  /// Calls [name], returns its result.
  Future<CallToolResult> call(String name, [Map<String, Object?>? args]) =>
      connection.callTool(CallToolRequest(name: name, arguments: args));

  /// Calls [name], returns its text decoded from json (throws when an
  /// error).
  Future<Object?> callJson(String name, [Map<String, Object?>? args]) async {
    var result = await call(name, args);
    var text = (result.content.first as TextContent).text;
    if (result.isError ?? false) {
      throw StateError(text);
    }
    return jsonDecode(text);
  }

  /// The text of the error of [name].
  Future<String> callError(String name, [Map<String, Object?>? args]) async {
    var result = await call(name, args);
    if (!(result.isError ?? false)) {
      throw StateError('$name did not fail');
    }
    return (result.content.first as TextContent).text;
  }

  /// Closes both.
  Future<void> close() async {
    await connection.shutdown();
    await server.shutdown();
  }
}
