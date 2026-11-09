@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tekartik_app_agent_mcp/app_agent_mcp.dart';
import 'package:test/test.dart';

import 'src/mcp_test_client.dart';

/// A Chrome debugging endpoint with one page whose js bridge has the command
/// `cmd`, no Chrome needed.
class _FakeChrome {
  late final HttpServer _server;
  final _sockets = <WebSocket>[];

  Uri get debugUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<_FakeChrome> start() async {
    var chrome = _FakeChrome();
    chrome._server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    chrome._server.listen(chrome._onRequest);
    return chrome;
  }

  Future<void> _onRequest(HttpRequest request) async {
    if (request.uri.path == '/json/list') {
      request.response.write(
        jsonEncode([
          {
            'type': 'page',
            'url': 'http://app/?agent',
            'webSocketDebuggerUrl':
                'ws://127.0.0.1:${_server.port}/devtools/page/1',
          },
        ]),
      );
      await request.response.close();
      return;
    }
    var socket = await WebSocketTransformer.upgrade(request);
    _sockets.add(socket);
    socket.listen((data) {
      var message = jsonDecode(data as String) as Map;
      Object? result = const <String, Object?>{};
      if (message['method'] == 'Runtime.evaluate') {
        var expression = (message['params'] as Map)['expression'] as String;
        Object? value;
        if (expression.startsWith('typeof')) {
          value = true;
        } else if (expression.contains('.commands()')) {
          value = [
            {
              'name': 'cmd',
              'description': 'A command.',
              'inputSchema': {'type': 'object'},
            },
          ];
        } else if (expression.contains('.run(')) {
          value = {'ok': true, 'result': 1};
        }
        result = {
          'result': {'type': 'object', 'value': value},
        };
      }
      socket.add(jsonEncode({'id': message['id'], 'result': result}));
    });
  }

  /// The page closes its debugging socket (the tab closed, Chrome gone).
  Future<void> closePage() async {
    for (var socket in _sockets) {
      await socket.close();
    }
  }

  Future<void> stop() async {
    await closePage();
    await _server.close(force: true);
  }
}

void main() {
  test('a request after the page closed fails at once', () async {
    var chrome = await _FakeChrome.start();
    var connection = await AgentChromeConnection.connect(chrome.debugUrl);
    try {
      expect((await connection.commands()).single['name'], 'cmd');
      await chrome.closePage();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await expectLater(
        connection.commands().timeout(const Duration(seconds: 5)),
        throwsA(isA<StateError>()),
      );
    } finally {
      await connection.close();
      await chrome.stop();
    }
  });

  test('app_connect to another page after the page closed', () async {
    var closed = await _FakeChrome.start();
    var other = await _FakeChrome.start();
    var client = await McpTestClient.start(
      newServer: (channel) => AgentMcpServer(
        channel,
        syncInterval: const Duration(milliseconds: 100),
      ),
    );
    try {
      await client.callJson('app_connect', {
        'chrome': closed.debugUrl.toString(),
      });
      await closed.closePage();
      // The periodic syncs run against the closed page.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      var connected = await client
          .callJson('app_connect', {'chrome': other.debugUrl.toString()})
          .timeout(const Duration(seconds: 10));
      expect((connected as Map)['commands'], ['cmd']);
      expect(await client.callJson('cmd'), 1);
    } finally {
      await client.close();
      await closed.stop();
      await other.stop();
    }
  });
}
