import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_app_http/app_http.dart' show HttpClientFactory;

import 'link.dart';
import 'web_scrapper.dart';
import 'web_scrapper_options.dart';

/// Runs the web scrapper command line with [arguments] (see
/// [WebScrapperCli]) and sets the process exit code.
///
/// A complete binary is:
///
/// ```dart
/// import 'package:tekartik_app_web_scrapper/app_web_scrapper_cli.dart';
///
/// Future<void> main(List<String> arguments) => webScrapperMain(arguments);
/// ```
Future<void> webScrapperMain(List<String> arguments) async {
  io.exitCode = await WebScrapperCli().run(arguments);
}

/// Exit code for invalid arguments (EX_USAGE).
const webScrapperExitCodeUsage = 64;

/// Web scrapper command line, `web_scrapper [options] <url> [<url>...]`.
///
/// Every dependency can be injected to embed it in another tool or test it
/// (memory file system and http client).
class WebScrapperCli {
  /// Name displayed in the usage.
  final String executableName;

  /// File system of the output directory, io by default.
  final FileSystem fileSystem;

  /// Http client factory, universal by default.
  final HttpClientFactory? httpClientFactory;

  /// Optional handler called for each content, see
  /// [WebScrapperOptions.onContent].
  final WebScrapperContentHandler? onContent;

  /// Output for progress and summary, stdout by default.
  final StringSink out;

  /// Output for usage errors, stderr by default.
  final StringSink err;

  /// Creates a command line runner, all parameters are optional.
  ///
  /// [executableName] defaults to `web_scrapper`, [fileSystem] to
  /// `fileSystemDefault` (io on the VM), [out] and [err] to stdout and
  /// stderr.
  WebScrapperCli({
    this.executableName = 'web_scrapper',
    FileSystem? fileSystem,
    this.httpClientFactory,
    this.onContent,
    StringSink? out,
    StringSink? err,
  }) : fileSystem = fileSystem ?? fileSystemDefault,
       out = out ?? io.stdout,
       err = err ?? io.stderr;

  /// Creates the argument parser (a new instance on each call, it can be
  /// extended by the caller).
  ArgParser createArgParser() => ArgParser()
    ..addOption(
      'out',
      abbr: 'o',
      valueHelp: 'dir',
      defaultsTo: '.',
      help: 'Output directory, files are saved as <dir>/<host>/<path>.',
    )
    ..addOption(
      'depth',
      abbr: 'd',
      valueHelp: 'n',
      help:
          'Maximum page link depth, 0 for the start pages only '
          '(their resources are always downloaded). No limit by default.',
    )
    ..addFlag(
      'external-resources',
      negatable: false,
      help:
          'Also download the resources (images, styles, scripts, fonts, '
          'media) hosted on other domains.',
    )
    ..addFlag(
      'external-links',
      negatable: false,
      help:
          'Also download the pages linked on other domains (their own links '
          'are not followed).',
    )
    ..addFlag(
      'scan-strings',
      negatable: false,
      help:
          'Also follow javascript and json strings that look like file '
          "paths (i.e. 'media.json', 'img/logo.png').",
    )
    ..addMultiOption(
      'host',
      valueHelp: 'host',
      help: 'Extra host part of the site (i.e. www.example.com).',
    )
    ..addMultiOption(
      'include',
      valueHelp: 'regexp',
      splitCommas: false,
      help: 'Only follow the urls matching one of these regular expressions.',
    )
    ..addMultiOption(
      'exclude',
      valueHelp: 'regexp',
      splitCommas: false,
      help: 'Never follow the urls matching one of these regular expressions.',
    )
    ..addOption(
      'max-files',
      valueHelp: 'n',
      help: 'Stop after processing n urls.',
    )
    ..addOption(
      'concurrency',
      abbr: 'j',
      valueHelp: 'n',
      defaultsTo: '4',
      help: 'Number of concurrent requests.',
    )
    ..addOption(
      'delay',
      valueHelp: 'ms',
      help: 'Delay before each request in milliseconds.',
    )
    ..addMultiOption(
      'header',
      valueHelp: 'name: value',
      splitCommas: false,
      help: 'Extra request header.',
    )
    ..addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Download again the files already in the output directory.',
    )
    ..addFlag(
      'quiet',
      abbr: 'q',
      negatable: false,
      help: 'Only print failures and the summary.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  /// Usage text.
  String get usage =>
      'Scrap a static web site: download the start urls and follow their '
      'links\n'
      '(html, css, javascript imports).\n'
      '\n'
      'Usage: $executableName [options] <url> [<url>...]\n'
      '\n'
      'Files already present in the output directory are not downloaded '
      'again\n'
      '(they are read back to follow their links) unless --force is set.\n'
      '\n'
      '${createArgParser().usage}';

  /// Runs the command line with [arguments].
  ///
  /// Returns the exit code: 0 on success (even if some links failed),
  /// 1 when every start url failed, [webScrapperExitCodeUsage] for invalid
  /// arguments.
  Future<int> run(List<String> arguments) async {
    final ArgResults results;
    final WebScrapper scrapper;
    try {
      results = createArgParser().parse(arguments);
      if (results.flag('help')) {
        out.writeln(usage);
        return 0;
      }
      scrapper = _createScrapper(results);
    } on FormatException catch (e) {
      err.writeln(e.message);
      err.writeln();
      err.writeln(usage);
      return webScrapperExitCodeUsage;
    }

    final quiet = results.flag('quiet');
    final result = await scrapper.run();
    final failed = result.failed.toList();
    if (quiet && failed.isNotEmpty) {
      for (final entry in failed) {
        out.writeln(_formatEntry(entry));
      }
    }
    out.writeln(
      '$result, saved in ${scrapper.outDirectory!.fs.path.normalize(scrapper.outDirectory!.path)}',
    );
    final startKeys = scrapper.startUris.map((uri) => uri.toString()).toSet();
    final startEntries = result.entries.where(
      (entry) => startKeys.contains(entry.uri.toString()),
    );
    if (startEntries.every((entry) => entry.isFailed)) {
      return 1;
    }
    return 0;
  }

  WebScrapper _createScrapper(ArgResults results) {
    int? intOption(String name) {
      final value = results.option(name);
      if (value == null) {
        return null;
      }
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 0) {
        throw FormatException('Invalid --$name value "$value".');
      }
      return parsed;
    }

    List<RegExp> regExps(String name) =>
        results.multiOption(name).map(RegExp.new).toList();

    if (results.rest.isEmpty) {
      throw const FormatException('Missing url.');
    }
    final startUris = results.rest.map((text) {
      // Allow `example.com`
      final uri = Uri.parse(text.contains('://') ? text : 'https://$text');
      if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
        throw FormatException('Invalid url "$text".');
      }
      return uri;
    }).toList();
    final includes = regExps('include');
    final excludes = regExps('exclude');
    final headers = <String, String>{};
    for (final header in results.multiOption('header')) {
      final index = header.indexOf(':');
      if (index <= 0) {
        throw FormatException(
          'Invalid --header "$header", expecting name: value.',
        );
      }
      headers[header.substring(0, index).trim()] = header
          .substring(index + 1)
          .trim();
    }
    final delay = intOption('delay');
    final quiet = results.flag('quiet');

    return WebScrapper(
      startUris: startUris,
      outDirectory: fileSystem.directory(results.option('out')!),
      httpClientFactory: httpClientFactory,
      options: WebScrapperOptions(
        maxDepth: intOption('depth'),
        followExternalResources: results.flag('external-resources'),
        followExternalLinks: results.flag('external-links'),
        scanStrings: results.flag('scan-strings'),
        hosts: results.multiOption('host'),
        filter: (includes.isEmpty && excludes.isEmpty)
            ? null
            : (uri) {
                final text = uri.toString();
                if (includes.isNotEmpty &&
                    !includes.any((regExp) => regExp.hasMatch(text))) {
                  return false;
                }
                return !excludes.any((regExp) => regExp.hasMatch(text));
              },
        maxFiles: intOption('max-files'),
        concurrency: intOption('concurrency') ?? 4,
        delay: delay == null ? null : Duration(milliseconds: delay),
        force: results.flag('force'),
        headers: headers.isEmpty ? null : headers,
        onContent: onContent,
        onEntry: quiet
            ? null
            : (entry) {
                out.writeln(_formatEntry(entry));
              },
      ),
    );
  }
}

String _formatEntry(WebScrapperEntry entry) {
  final sb = StringBuffer();
  switch (entry.status) {
    case WebScrapperEntryStatus.downloaded:
      sb.write('${entry.statusCode ?? ''}'.padLeft(5));
    case WebScrapperEntryStatus.cached:
      sb.write('cache');
    case WebScrapperEntryStatus.failed:
      sb.write(
        entry.statusCode == null ? 'ERROR' : '${entry.statusCode}'.padLeft(5),
      );
  }
  sb.write(' ${entry.uri}');
  if (entry.finalUri != entry.uri) {
    sb.write(' => ${entry.finalUri}');
  }
  if (entry.isFailed) {
    if (entry.statusCode == null) {
      sb.write(': ${entry.error}');
    }
    if (entry.referrer != null) {
      sb.write(' (from ${entry.referrer})');
    }
  } else {
    if (entry.localPath != null) {
      sb.write(' -> ${entry.localPath}');
    }
    if (entry.size != null) {
      sb.write(' (${_formatSize(entry.size!)})');
    }
    if (entry.kind == WebScrapperLinkKind.page && entry.depth > 0) {
      sb.write(' depth ${entry.depth}');
    }
  }
  return sb.toString();
}

String _formatSize(int size) {
  if (size < 1024) {
    return '$size B';
  } else if (size < 1024 * 1024) {
    return '${(size / 1024).toStringAsFixed(1)} KB';
  }
  return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
}
