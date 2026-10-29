@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:tekartik_app_agent_mcp/app_agent_mcp.dart';
import 'package:test/test.dart';

import 'src/mcp_test_client.dart';

/// A page with a js bridge as `agentInit` installs it, and a semantics id.
const _html = '''
<!doctype html>
<html><body>
<div flt-semantics-identifier="hello" onclick="this.textContent = 'tapped'">Hello</div>
<script>
window.tekartikAgent = {
  commands: () => [{
    name: 'echo',
    description: 'Returns [text].',
    inputSchema: {type: 'object', properties: {text: {type: 'string'}}}
  }],
  run: async (name, args) => name === 'echo'
    ? {ok: true, result: args.text}
    : {ok: false, error: 'unknown command ' + name}
};
</script>
</body></html>
''';

final _url = Uri.dataFromString(_html, mimeType: 'text/html');

String? _noChrome() {
  try {
    agentChromeExecutable();
    return null;
  } catch (e) {
    return '$e';
  }
}

void main() {
  var skip = _noChrome();

  test('chrome connection', () async {
    var connection = await AgentChromeConnection.launch(
      _url,
      // The CI runners may refuse the Chrome sandbox.
      arguments: [if (Platform.environment['CI'] == 'true') '--no-sandbox'],
    );
    try {
      expect(
        [for (var command in await connection.commands()) command['name']],
        ['echo'],
      );
      expect((await connection.run('echo', {'text': 'hi'})).result, 'hi');
      expect((await connection.run('none')).error, 'unknown command none');
      expect(await connection.page.ids(), ['hello']);
      await connection.page.tap('hello');
      expect(await connection.page.text('hello'), 'tapped');
      expect(base64Decode(await connection.screenshot()), isNotEmpty);
    } finally {
      await connection.close();
    }
  }, skip: skip);

  test('mcp server on a page', () async {
    var client = await McpTestClient.start();
    try {
      var connected =
          (await client.callJson('app_connect', {'open': _url.toString()}))
              as Map;
      expect(connected['commands'], ['echo']);
      expect(await client.callJson('echo', {'text': 'hi'}), 'hi');
      expect(await client.callJson('app_ids'), ['hello']);
      var screenshot = await client.call('app_screenshot');
      expect((screenshot.content.single as ImageContent).mimeType, 'image/png');
    } finally {
      await client.close();
    }
  }, skip: skip);
}
