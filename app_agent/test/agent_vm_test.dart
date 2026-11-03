@TestOn('vm')
library;

import 'dart:developer';
import 'dart:isolate';

import 'package:tekartik_app_agent/app_agent.dart';
import 'package:test/test.dart';

void main() {
  test('agentVmRegister', () {
    final commands = AgentCommands();
    expect(agentVmRegister(commands), isTrue);
    // Once.
    expect(agentVmRegister(commands), isTrue);
  });

  test('agentVmRegister names already taken', () async {
    // A new isolate: the extensions of another one (a dev menu agent) are
    // there first.
    final registered = await Isolate.run(() {
      registerExtension(
        agentVmCommandsExtension,
        (method, parameters) async => ServiceExtensionResponse.result('{}'),
      );
      return agentVmRegister(AgentCommands());
    });
    expect(registered, isFalse);
  });
}
