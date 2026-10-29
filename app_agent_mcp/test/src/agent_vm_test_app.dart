import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The running `test/data/agent_vm_app.dart` and its VM service uri.
class AgentVmTestApp {
  /// Its process.
  final Process process;

  /// Its VM service uri (http).
  final String vmServiceUri;

  AgentVmTestApp._(this.process, this.vmServiceUri);

  /// Starts it with a VM service on a free port.
  static Future<AgentVmTestApp> start() async {
    var process = await Process.start(Platform.resolvedExecutable, [
      '--enable-vm-service=0',
      'test/data/agent_vm_app.dart',
    ]);
    var uri = Completer<String>();
    var ready = Completer<void>();
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          var match = RegExp(
            r'Dart VM service is listening on (http://\S+)',
          ).firstMatch(line);
          if (match != null && !uri.isCompleted) {
            uri.complete(match.group(1)!);
          }
          if (line == 'ready' && !ready.isCompleted) {
            ready.complete();
          }
        });
    process.stderr.drain<void>().ignore();
    var vmServiceUri = await uri.future.timeout(const Duration(seconds: 60));
    await ready.future.timeout(const Duration(seconds: 60));
    return AgentVmTestApp._(process, vmServiceUri);
  }

  /// Stops it.
  Future<void> stop() async {
    await process.stdin.close();
    await process.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        process.kill();
        return -1;
      },
    );
  }
}
