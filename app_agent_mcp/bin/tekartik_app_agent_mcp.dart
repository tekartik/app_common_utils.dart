import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:tekartik_app_agent_mcp/app_agent_mcp.dart';

/// The MCP server (stdio) of tekartik_app_agent_mcp: connects to the app
/// given (or later with the app_connect tool) and serves its commands as
/// tools. Logs go to stderr.
Future<void> main(List<String> arguments) async {
  var parser = ArgParser()
    ..addOption('vm-service', help: 'The VM service uri of a debug run')
    ..addOption('open', help: 'A url to open in a new Chrome (with ?agent)')
    ..addFlag('headless', defaultsTo: true, help: 'A headless Chrome')
    ..addOption('chrome', help: 'A Chrome debugging endpoint')
    ..addOption('page', help: 'A part of the page url (with --chrome)')
    ..addMultiOption(
      'chrome-argument',
      help: 'An argument of the Chrome it starts (--no-sandbox...)',
    )
    ..addFlag('help', abbr: 'h', negatable: false);
  var args = parser.parse(arguments);
  if (args.flag('help')) {
    stderr.writeln(
      'tekartik_app_agent_mcp: an MCP server (stdio) driving a running app '
      'by its commands.\n${parser.usage}',
    );
    return;
  }
  AgentAppConnection? connection;
  if (args.option('vm-service') case var uri?) {
    connection = await AgentVmConnection.connect(uri);
  } else if (args.option('open') case var url?) {
    connection = await AgentChromeConnection.launch(
      Uri.parse(url),
      headless: args.flag('headless'),
      arguments: args.multiOption('chrome-argument'),
    );
  } else if (args.option('chrome') case var url?) {
    connection = await AgentChromeConnection.connect(
      Uri.parse(url),
      page: args.option('page'),
    );
  }
  if (connection != null) {
    stderr.writeln('connected to ${connection.description}');
  }
  var server = AgentMcpServer(
    stdioChannel(input: stdin, output: stdout),
    connection: connection,
    chromeArguments: args.multiOption('chrome-argument'),
  );
  await server.done;
  await server.disconnect();
}
