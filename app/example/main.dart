// ignore_for_file: avoid_print

import 'dart:async';

import 'package:tekartik_app_common_utils/asset/asset_bundle.dart';
import 'package:tekartik_app_common_utils/auto_dispose.dart';
import 'package:tekartik_app_common_utils/lazy_runner.dart';
import 'package:tekartik_app_common_utils/single_flight.dart';
import 'package:tekartik_app_common_utils/yaml_utils.dart';

/// Saves in the background: edits in a row give a single save.
class Document {
  var _text = '';
  var saveCount = 0;
  late final _saver = LazyRunner<void>(
    action: (index) async {
      saveCount++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      print('saved #$index: $_text');
    },
  );

  void edit(String text) {
    _text = text;
    _saver.trigger();
  }

  Future<void> close() async {
    // Wait for the pending save, then stop the runner.
    await _saver.waitTriggered();
    await _saver.close();
  }
}

/// Owns a subscription, released by audiDisposeAll().
class Ticker with AutoDisposeMixin {
  var ticks = 0;
  Ticker(Stream<void> source) {
    audiAddStreamSubscription(source.listen((_) => ticks++));
  }

  void dispose() => audiDisposeAll();
}

Future<void> main() async {
  // LazyRunner: coalesce repeated work.
  var document = Document()
    ..edit('a')
    ..edit('ab')
    ..edit('abc');
  await document.close();
  print('saves: ${document.saveCount}'); // 1

  // SingleFlight: concurrent callers share one execution.
  var loads = 0;
  var config = SingleFlight<String>(() async {
    loads++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return 'config v$loads';
  });
  print(await Future.wait([config.waitOrRun(), config.waitOrRun()]));
  print('loads: $loads'); // 1
  await config.close();

  // AutoDispose: one call releases everything registered.
  var source = StreamController<void>.broadcast();
  var ticker = Ticker(source.stream);
  source.add(null);
  await Future<void>.delayed(Duration.zero);
  ticker.dispose();
  source.add(null);
  await Future<void>.delayed(Duration.zero);
  print('ticks: ${ticker.ticks}'); // 1
  await source.close();

  // YAML config read through an asset bundle (a memory one here, wrap
  // Flutter's rootBundle in an app).
  TkAssetBundle bundle = TkAssetBundleMemory()
    ..setString('assets/config.yaml', 'name: my_app\nflags:\n  debug: true\n');
  var model = decodeYamlMap(await bundle.loadString('assets/config.yaml'));
  print(model['name']); // my_app
  print((model['flags'] as Map)['debug']); // true
}
