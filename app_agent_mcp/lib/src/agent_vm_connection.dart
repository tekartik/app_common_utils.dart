import 'dart:async';
import 'dart:convert';

import 'package:tekartik_app_agent/app_agent.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'agent_app_connection.dart';

/// The web socket uri of a VM service from the uri `flutter run` or `dart
/// run --enable-vm-service` prints (`http://127.0.0.1:8181/abc=/`, its
/// DevTools link `...?uri=http://...`, or already `ws://.../ws`).
Uri agentVmServiceWsUri(String text) {
  var uri = Uri.parse(text.trim());
  var inner = uri.queryParameters['uri'];
  if (inner != null) {
    return agentVmServiceWsUri(inner);
  }
  var scheme = switch (uri.scheme) {
    'http' || 'ws' => 'ws',
    'https' || 'wss' => 'wss',
    _ => throw ArgumentError.value(text, 'uri', 'http(s) or ws(s) expected'),
  };
  var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.lastOrNull != 'ws') {
    segments.add('ws');
  }
  return uri.replace(scheme: scheme, pathSegments: segments, query: null);
}

/// The commands of a Dart or Flutter app in a debug or profile run,
/// through its VM service extensions (`agentVmRegister` of
/// tekartik_app_agent, called by `agentInit` of
/// tekartik_app_agent_flutter): [agentVmCommandsExtension] and
/// [agentVmRunExtension] of the isolate that registered them, found again
/// after a hot restart.
class AgentVmConnection implements AgentAppConnection {
  /// The VM service.
  final VmService service;

  /// Its web socket uri.
  final Uri wsUri;

  String? _isolateId;

  AgentVmConnection._(this.service, this.wsUri);

  /// Connects to the VM service [uri] (see [agentVmServiceWsUri]) and waits
  /// up to [timeout] for an isolate with the agent extensions.
  static Future<AgentVmConnection> connect(
    String uri, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    var wsUri = agentVmServiceWsUri(uri);
    var service = await vmServiceConnectUri(wsUri.toString());
    var connection = AgentVmConnection._(service, wsUri);
    try {
      await connection._findIsolate(timeout: timeout);
    } catch (_) {
      await service.dispose();
      rethrow;
    }
    return connection;
  }

  @override
  String get description => 'vm service $wsUri';

  Future<String> _findIsolate({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    var stopwatch = Stopwatch()..start();
    while (true) {
      var vm = await service.getVM();
      for (var ref in vm.isolates ?? const <IsolateRef>[]) {
        try {
          var isolate = await service.getIsolate(ref.id!);
          if (isolate.extensionRPCs?.contains(agentVmCommandsExtension) ??
              false) {
            return _isolateId = isolate.id!;
          }
        } on SentinelException {
          // An isolate gone meanwhile.
        }
      }
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'no isolate with $agentVmCommandsExtension: does the app call '
          'agentInit (or agentVmRegister) in a debug or profile run?',
          timeout,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Calls the extension [method], finding the isolate again once when it is
  /// gone (a hot restart).
  Future<Map<String, Object?>> _call(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    Future<Map<String, Object?>> call() async {
      var isolateId = _isolateId ?? await _findIsolate();
      var response = await service.callServiceExtension(
        method,
        isolateId: isolateId,
        args: args,
      );
      return response.json ?? const {};
    }

    try {
      return await call();
    } on SentinelException {
      _isolateId = null;
    } on RPCError {
      // An isolate restarted (its extension not found) or gone.
      _isolateId = null;
    }
    return call();
  }

  @override
  Future<List<Map<String, Object?>>> commands() async => agentCommandsFromJson(
    (await _call(agentVmCommandsExtension))['commands'],
  );

  @override
  Future<AgentCommandResult> run(
    String name, [
    Map<String, Object?>? args,
  ]) async => agentCommandResultFromJson(
    await _call(agentVmRunExtension, {
      'name': name,
      'args': jsonEncode(args ?? const <String, Object?>{}),
    }),
  );

  @override
  Future<void> close() => service.dispose();
}
