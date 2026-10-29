import 'package:tekartik_app_agent/app_agent.dart';
import 'package:tekartik_app_agent_mcp/app_agent_mcp.dart';
import 'package:test/test.dart';

import 'src/mcp_test_client.dart';

void main() {
  test('a server of its own commands', () async {
    var registry = AgentCommands();
    AgentCommandsRegistration? opened;
    registry.add([
      AgentCommand(
        name: 'open',
        description: 'Opens: adds the command read.',
        run: (_) {
          opened ??= registry.add([
            AgentCommand(
              name: 'read',
              description: 'Reads.',
              run: (_) => {'value': 1},
            ),
          ]);
          return true;
        },
      ),
      AgentCommand(
        name: 'close',
        description: 'Closes.',
        run: (_) {
          opened?.remove();
          opened = null;
          return true;
        },
      ),
    ]);
    var client = await McpTestClient.start(
      newServer: (channel) => AgentMcpServer(
        channel,
        connection: AgentLocalConnection(registry: registry),
        connectTools: false,
        syncInterval: null,
      ),
    );
    try {
      var tools = await client.tools();
      expect(tools, isNot(contains('app_connect')));
      expect(tools, isNot(contains('app_screenshot')));
      expect(tools, containsAll(['app_commands', 'app_run', 'open', 'close']));
      expect(await client.callJson('open'), isTrue);
      expect(await client.tools(), contains('read'));
      expect(await client.callJson('read'), {'value': 1});
      await client.callJson('close');
      expect(await client.tools(), isNot(contains('read')));
    } finally {
      await client.close();
    }
  });
}
