import 'package:dev_build/shell.dart';
import 'package:tekartik_ci/setup_ci_github.dart';

Future main() async {
  try {
    await sudoSetupSqlite3Lib();
  } catch (e) {
    print('Could not setup sqlite3 lib: $e');
  }
  await run('dart pub global activate process_run');
}
