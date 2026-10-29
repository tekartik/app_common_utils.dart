import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tekartik_app_agent/app_agent.dart';

import 'agent_app_connection.dart';

/// A Chrome DevTools protocol session on a page target (its web socket).
class _CdpSession {
  final WebSocket _socket;
  var _lastId = 0;
  final _pending = <int, Completer<Map<String, Object?>>>{};

  _CdpSession(this._socket) {
    _socket.listen(
      (data) {
        var message = jsonDecode(data as String) as Map<String, Object?>;
        var completer = _pending.remove(message['id']);
        if (completer == null) {
          return;
        }
        if (message['error'] case Map error) {
          completer.completeError(StateError('cdp: ${error['message']}'));
        } else {
          completer.complete(
            (message['result'] as Map?)?.cast<String, Object?>() ?? const {},
          );
        }
      },
      onDone: () {
        for (var completer in _pending.values) {
          completer.completeError(StateError('cdp: page closed'));
        }
        _pending.clear();
      },
    );
  }

  static Future<_CdpSession> connect(String wsUrl) async =>
      _CdpSession(await WebSocket.connect(wsUrl));

  Future<Map<String, Object?>> send(
    String method, [
    Map<String, Object?> params = const {},
  ]) {
    var id = ++_lastId;
    var completer = _pending[id] = Completer<Map<String, Object?>>();
    _socket.add(jsonEncode({'id': id, 'method': method, 'params': params}));
    return completer.future;
  }

  Future<void> close() => _socket.close();
}

/// The Chrome executables looked for on the PATH, after `CHROME_EXECUTABLE`.
const _chromeNames = [
  'google-chrome',
  'google-chrome-stable',
  'chromium',
  'chromium-browser',
];

const _macChrome =
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

/// The Chrome executable: `CHROME_EXECUTABLE`, else the first of
/// google-chrome, chromium... on the PATH.
String agentChromeExecutable() {
  var env = Platform.environment['CHROME_EXECUTABLE'];
  if (env != null && env.isNotEmpty) {
    return env;
  }
  if (Platform.isMacOS && File(_macChrome).existsSync()) {
    return _macChrome;
  }
  if (Platform.isWindows) {
    for (var variable in [
      'PROGRAMFILES',
      'PROGRAMFILES(X86)',
      'LOCALAPPDATA',
    ]) {
      var dir = Platform.environment[variable];
      var file = File('$dir\\Google\\Chrome\\Application\\chrome.exe');
      if (dir != null && file.existsSync()) {
        return file.path;
      }
    }
  }
  var separator = Platform.isWindows ? ';' : ':';
  var suffix = Platform.isWindows ? '.exe' : '';
  for (var dir in (Platform.environment['PATH'] ?? '').split(separator)) {
    for (var name in _chromeNames) {
      var file = File('$dir${Platform.pathSeparator}$name$suffix');
      if (file.existsSync()) {
        return file.path;
      }
    }
  }
  throw StateError('Chrome not found: set CHROME_EXECUTABLE');
}

/// The page targets of the Chrome debugging endpoint [debugUrl]
/// (`http://127.0.0.1:9222`): `id`, `url`, `webSocketDebuggerUrl`...
Future<List<Map<String, Object?>>> agentChromePages(Uri debugUrl) async {
  var client = HttpClient();
  try {
    var request = await client.getUrl(debugUrl.resolve('/json/list'));
    var response = await request.close();
    var text = await utf8.decodeStream(response);
    return [
      for (var target in jsonDecode(text) as List)
        if ((target as Map)['type'] == 'page') target.cast<String, Object?>(),
    ];
  } finally {
    client.close();
  }
}

/// The commands of a web app (Flutter web, release builds included) opened
/// with `?agent`, through its js bridge (`window.tekartikAgent`) over the
/// Chrome DevTools protocol: a page of a Chrome started with
/// `--remote-debugging-port` ([connect]) or of a Chrome it starts
/// ([launch], headless by default). Also its semantics ids ([page]: ids,
/// tap, text, with `?agent` or `?semantics`) and its [screenshot].
class AgentChromeConnection implements AgentAppConnection {
  final _CdpSession _session;

  /// The page url when connected.
  final String url;

  final Process? _process;
  final Directory? _userDataDir;

  /// The driver of the semantics ids and of the js bridge of the page.
  late final page = AgentWebPage(evaluate);

  AgentChromeConnection._(
    this._session,
    this.url, {
    this._process,
    this._userDataDir,
  });

  /// Connects to the page of the Chrome debugging endpoint [debugUrl]
  /// (`http://127.0.0.1:9222`) whose url contains [page], the first page
  /// otherwise.
  static Future<AgentChromeConnection> connect(
    Uri debugUrl, {
    String? page,
  }) async {
    var pages = await agentChromePages(debugUrl);
    var target = pages.firstWhere(
      (target) => page == null || '${target['url']}'.contains(page),
      orElse: () => throw StateError(
        'no page${page == null ? '' : ' with $page'}, pages: '
        '${pages.map((target) => target['url']).join(', ')}',
      ),
    );
    var session = await _CdpSession.connect(
      target['webSocketDebuggerUrl'] as String,
    );
    var connection = AgentChromeConnection._(session, '${target['url']}');
    await connection._init();
    return connection;
  }

  /// Starts a Chrome (headless unless [headless] is false, [width] x
  /// [height], with [arguments] more) on [url] (with `?agent` for the
  /// commands) and connects to it.
  static Future<AgentChromeConnection> launch(
    Uri url, {
    bool headless = true,
    int width = 1280,
    int height = 800,
    String? executable,
    List<String> arguments = const [],
  }) async {
    var userDataDir = await Directory.systemTemp.createTemp('agent_chrome_');
    var process = await Process.start(executable ?? agentChromeExecutable(), [
      if (headless) ...[
        '--headless=new',
        // WebGL for the Flutter renderers without a GPU.
        '--use-angle=swiftshader',
        '--enable-unsafe-swiftshader',
        '--hide-scrollbars',
      ],
      '--remote-debugging-port=0',
      '--user-data-dir=${userDataDir.path}',
      '--no-first-run',
      '--no-default-browser-check',
      '--window-size=$width,$height',
      ...arguments,
      url.toString(),
    ]);
    try {
      var devTools = Completer<Uri>();
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            var match = RegExp(
              r'DevTools listening on (ws://\S+)',
            ).firstMatch(line);
            if (match != null && !devTools.isCompleted) {
              devTools.complete(Uri.parse(match.group(1)!));
            }
          });
      process.stdout.drain<void>().ignore();
      var browserWs = await devTools.future.timeout(
        const Duration(seconds: 30),
      );
      var debugUrl = Uri(
        scheme: 'http',
        host: browserWs.host,
        port: browserWs.port,
      );
      var pages = await agentChromePages(debugUrl);
      var target = pages.first;
      var session = await _CdpSession.connect(
        target['webSocketDebuggerUrl'] as String,
      );
      var connection = AgentChromeConnection._(
        session,
        url.toString(),
        process: process,
        userDataDir: userDataDir,
      );
      await connection._init();
      return connection;
    } catch (_) {
      process.kill();
      await _deleteDir(userDataDir);
      rethrow;
    }
  }

  static Future<void> _deleteDir(Directory dir) async {
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // Chrome may still hold a file.
    }
  }

  Future<void> _init() async {
    await _session.send('Runtime.enable');
    await _session.send('Page.enable');
  }

  @override
  String get description =>
      '${_process == null ? 'chrome' : 'launched chrome'} page $url';

  /// Evaluates the javascript [expression] in the page, returns its json
  /// value (see [AgentEvaluate]).
  Future<Object?> evaluate(
    String expression, {
    bool awaitPromise = false,
  }) async {
    var result = await _session.send('Runtime.evaluate', {
      'expression': expression,
      'returnByValue': true,
      'awaitPromise': awaitPromise,
    });
    if (result['exceptionDetails'] case Map details) {
      var exception = details['exception'] as Map?;
      throw StateError('js: ${exception?['description'] ?? details['text']}');
    }
    return (result['result'] as Map?)?['value'];
  }

  /// Waits up to [timeout] for the js bridge of the app (loaded with
  /// `?agent`).
  Future<void> waitForCommands({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    var stopwatch = Stopwatch()..start();
    while (!await page.hasCommands()) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'no window.$agentBridgeName: is the app opened with ?agent and does '
          'it call agentInit?',
          timeout,
        );
      }
      await Future<void>.delayed(page.pollInterval);
    }
  }

  @override
  Future<List<Map<String, Object?>>> commands() async {
    await waitForCommands();
    return agentCommandsFromJson(
      await evaluate('window.$agentBridgeName.commands()'),
    );
  }

  @override
  Future<AgentCommandResult> run(
    String name, [
    Map<String, Object?>? args,
  ]) async {
    await waitForCommands();
    return agentCommandResultFromJson(
      await evaluate(
        'window.$agentBridgeName.run(${jsonEncode(name)}, '
        '${jsonEncode(args ?? const <String, Object?>{})})',
        awaitPromise: true,
      ),
    );
  }

  /// Opens [url] in the page.
  Future<void> navigate(Uri url) async {
    await _session.send('Page.navigate', {'url': url.toString()});
  }

  /// A png screenshot of the page, base64.
  Future<String> screenshot() async =>
      (await _session.send('Page.captureScreenshot', {'format': 'png'}))['data']
          as String;

  @override
  Future<void> close() async {
    await _session.close();
    var process = _process;
    if (process != null) {
      process.kill();
      await process.exitCode.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    }
    if (_userDataDir case var dir?) {
      await _deleteDir(dir);
    }
  }
}
