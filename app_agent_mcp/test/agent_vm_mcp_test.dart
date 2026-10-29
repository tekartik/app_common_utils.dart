@TestOn('vm')
library;

import 'package:tekartik_app_agent_mcp/app_agent_mcp.dart';
import 'package:test/test.dart';

import 'src/agent_vm_test_app.dart';
import 'src/mcp_test_client.dart';

void main() {
  late AgentVmTestApp app;
  setUpAll(() async {
    app = await AgentVmTestApp.start();
  });
  tearDownAll(() => app.stop());

  test('agentVmServiceWsUri', () {
    expect(
      agentVmServiceWsUri('http://127.0.0.1:8181/abc=/').toString(),
      'ws://127.0.0.1:8181/abc=/ws',
    );
    expect(
      agentVmServiceWsUri('ws://127.0.0.1:8181/abc=/ws').toString(),
      'ws://127.0.0.1:8181/abc=/ws',
    );
    expect(
      agentVmServiceWsUri(
        'http://127.0.0.1:9100/devtools/?uri=http://127.0.0.1:8181/abc=/',
      ).toString(),
      'ws://127.0.0.1:8181/abc=/ws',
    );
  });

  test('vm connection', () async {
    var connection = await AgentVmConnection.connect(app.vmServiceUri);
    try {
      var names = [
        for (var command in await connection.commands()) command['name'],
      ];
      expect(names, containsAll(['echo', 'fail', 'extra']));
      var result = await connection.run('echo', {'text': 'hi'});
      expect(result.ok, isTrue);
      expect(result.result, 'hi');
      expect((await connection.run('fail')).error, 'failed on purpose');
      expect(
        (await connection.run('none')).error,
        startsWith('unknown command none'),
      );
    } finally {
      await connection.close();
    }
  });

  test('mcp server', () async {
    var client = await McpTestClient.start();
    try {
      expect(await client.tools(), containsAll(['app_connect', 'app_run']));
      expect(
        await client.callError('app_run', {'name': 'echo'}),
        'not connected to an app: app_connect first',
      );
      var connected =
          (await client.callJson('app_connect', {
                'vmService': app.vmServiceUri,
              }))
              as Map;
      expect(connected['commands'], containsAll(['echo', 'extra']));
      expect(await client.tools(), containsAll(['echo', 'fail', 'extra']));
      expect(await client.callJson('echo', {'text': 'hi'}), 'hi');
      expect(
        await client.callJson('app_run', {
          'name': 'echo',
          'args': {'text': 'ho'},
        }),
        'ho',
      );
      expect(await client.callError('fail'), 'failed on purpose');

      // A command adding a command: a new tool, the client notified.
      var changed = client.connection.toolListChanged.first;
      await client.callJson('extra');
      await changed;
      expect(await client.tools(), contains('extra_one'));
      expect(await client.callJson('extra_one'), 1);
      await client.callJson('extra', {'on': false});
      expect(await client.tools(), isNot(contains('extra_one')));

      expect(
        await client.callError('app_ids'),
        'a web page only (app_connect with open or chrome)',
      );
      await client.callJson('app_commands');
      expect((await client.call('app_disconnect')).isError, isNot(isTrue));
      expect(await client.tools(), isNot(contains('echo')));
    } finally {
      await client.close();
    }
  });
}
