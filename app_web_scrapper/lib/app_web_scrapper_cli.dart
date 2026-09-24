/// Command line helpers of the web scrapper (io only).
///
/// A complete binary is:
///
/// ```dart
/// import 'package:tekartik_app_web_scrapper/app_web_scrapper_cli.dart';
///
/// Future<void> main(List<String> arguments) => webScrapperMain(arguments);
/// ```
library;

export 'app_web_scrapper.dart';
export 'src/cli.dart'
    show WebScrapperCli, webScrapperMain, webScrapperExitCodeUsage;
