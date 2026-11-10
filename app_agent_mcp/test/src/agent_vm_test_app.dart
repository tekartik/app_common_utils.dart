import 'dart:async';
import 'dart:io';

import 'package:process_run/shell.dart';

/// The running `test/data/agent_vm_app.dart` and its VM service uri.
class AgentVmTestApp {
  /// Its process.
  final Process process;

  /// Its input, ended to stop it.
  final ShellLinesController _input;

  /// Its output and error output.
  final ShellLinesController _output;

  /// The end of its run.
  final Future<void> _done;

  /// Its VM service uri (http).
  final String vmServiceUri;

  AgentVmTestApp._(
    this.process,
    this._input,
    this._output,
    this._done,
    this.vmServiceUri,
  );

  /// Starts it with a VM service on a free port.
  static Future<AgentVmTestApp> start() async {
    var input = ShellLinesController();
    var output = ShellLinesController();
    var shell = Shell(
      stdin: input.binaryStream,
      stdout: output.sink,
      stderr: output.sink,
      verbose: false,
      throwOnError: false,
    );
    var uri = Completer<String>();
    var ready = Completer<void>();
    output.stream.listen((line) {
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
    var started = Completer<Process>();
    var done = shell
        .runExecutableArguments(Platform.resolvedExecutable, [
          '--enable-vm-service=0',
          'test/data/agent_vm_app.dart',
        ], onProcess: started.complete)
        .then<void>((_) {});
    var process = await started.future;
    var vmServiceUri = await uri.future.timeout(const Duration(seconds: 60));
    await ready.future.timeout(const Duration(seconds: 60));
    return AgentVmTestApp._(process, input, output, done, vmServiceUri);
  }

  /// Stops it.
  Future<void> stop() async {
    _input.close();
    await process.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        process.kill();
        return -1;
      },
    );
    await _done;
    _output.close();
  }
}
