import 'dart:io';

import 'package:tekartik_app_agent/app_agent.dart';

/// A Dart program exposing its commands as VM service extensions, run by
/// the tests with `--enable-vm-service`: prints `ready`, stops when its
/// stdin closes.
Future<void> main() async {
  AgentCommandsRegistration? extra;
  agentCommands.add([
    AgentCommand(
      name: 'echo',
      description: 'Returns [text].',
      inputSchema: AgentSchema.object(
        {'text': AgentSchema.string('A text')},
        required: ['text'],
      ),
      run: (args) => args['text'],
    ),
    AgentCommand(
      name: 'fail',
      description: 'Fails.',
      run: (_) => throw AgentCommandException('failed on purpose'),
    ),
    AgentCommand(
      name: 'extra',
      description:
          'Adds the command extra_one (on: true, the default) or removes '
          'it.',
      inputSchema: AgentSchema.object({
        'on': AgentSchema.boolean('False to remove'),
      }),
      run: (args) {
        if (args['on'] != false) {
          extra ??= agentCommands.add([
            AgentCommand(
              name: 'extra_one',
              description: 'One more.',
              run: (_) => 1,
            ),
          ]);
        } else {
          extra?.remove();
          extra = null;
        }
        return agentCommands.byName.keys.toList()..sort();
      },
    ),
  ]);
  agentVmRegister(agentCommands);
  stdout.writeln('ready');
  await stdin.drain<void>();
  exit(0);
}
