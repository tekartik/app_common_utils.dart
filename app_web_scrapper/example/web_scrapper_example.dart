// ignore_for_file: avoid_print

import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_app_web_scrapper/app_web_scrapper.dart';

/// Scraps a site to `.local/site/<host>` and lists the titles of its pages.
Future<void> main(List<String> arguments) async {
  final url = arguments.isEmpty ? 'https://example.com/' : arguments.first;
  final scrapper = WebScrapper(
    startUris: [Uri.parse(url)],
    outDirectory: fileSystemDefault.directory('.local/site'),
    options: WebScrapperOptions(
      maxDepth: 2,
      onContent: (content) {
        final document = content.document;
        if (document != null) {
          print('${content.uri}: ${document.title}');
        }
      },
      onEntry: (entry) {
        if (entry.isFailed) {
          print('failed ${entry.uri} (from ${entry.referrer}): ${entry.error}');
        }
      },
    ),
  );
  final result = await scrapper.run();
  print(result);
}
