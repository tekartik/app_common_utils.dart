---
name: tekartik-app-dev-menu-setup
description: >-
  Use when writing an interactive developer or manual test menu that runs
  unchanged in a console (dart run) and in the browser (webdev serve) with
  tekartik_app_dev_menu: mainMenu(arguments, declare), menu, item, enter,
  leave, enterItem, leaveItem, command, write, writeln, prompt, solo_item,
  solo_menu, the test/group/expect aliases of test_menu.dart, and persisted
  KeyValue settings ('NAME'.kvFromVar(defaultValue:), kv.value, kv.valid,
  kv.get, kv.set, kv.delete, keyValuesMenu; process_run shell env vars on io,
  localStorage on the web) from package:tekartik_app_dev_menu/dev_menu.dart.
---

# Universal dev menu (tekartik_app_dev_menu)

`tekartik_app_dev_menu` bundles `tekartik_test_menu`,
`tekartik_test_menu_io` and `tekartik_test_menu_browser` behind one import:
declare menus and items once, run them from the terminal (numbered menu on
stdin/stdout) or from a web page (clickable menu with an output panel), and
keep developer settings (API keys, ids, urls) in persisted key values.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_dev_menu:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_dev_menu
  ```
  The three `tekartik_test_menu*` packages come with it. For a browser
  build add `build_runner` and `build_web_compilers` as dev dependencies
  and activate `webdev` (`dart pub global activate webdev`).
* Import `package:tekartik_app_dev_menu/dev_menu.dart`. It exports the
  menu DSL of `tekartik_test_menu` (`menu`, `item`, `enter`, `leave`,
  `enterItem`, `leaveItem`, `command`, `write`, `writeln`, `prompt`,
  `showMenu`, `popMenu`, `menuRun`, `solo_item`, `solo_menu`), the
  universal entry point `mainMenu` (same as `mainMenuUniversal`) and the
  key value helpers (`KeyValue`, `kvFromVar`, `keyValuesMenu`, the `get`
  / `set` / `delete` extension). `package:tekartik_app_dev_menu/test_menu.dart`
  re-exports all of it plus `test`, `group`, `solo_test`, `solo_group`,
  `expect`, `fail` and the `matcher` package for test shaped menus.
* Entry point, one file for both platforms:
  `Future<void> main(List<String> arguments) => mainMenu(arguments, () { ... });`
  The declare callback must be synchronous and only call `menu`, `item`
  (and `keyValuesMenu`, `enter`, `leave`); item bodies may be `async`. Put
  it in `example/main.dart` or `web/main.dart` next to an `index.html`
  that loads `main.dart.js`.
* `menu(name, body, {cmd, group, solo})` nests a sub menu, `item(name,
  body, {cmd, solo})` a runnable entry; `cmd` is a shortcut typed instead
  of the number. `solo:` / `solo_item` / `solo_menu` run only that entry
  and are annotated `@doNotSubmit`: for local debugging, remove before
  committing. `enter` / `leave` register hooks run when entering / leaving
  the enclosing menu, `enterItem` / `leaveItem` around each of its items,
  `command` receives unrecognized input.
* Output through `write(message)` / `writeln(message)` (same thing) so it
  shows in the browser panel as well as on stdout; `print` only reaches
  the console. `await prompt('question')` asks the user for a line
  (`Future<String>`). An exception thrown by an item is displayed and the
  menu keeps running.
* Console: `dart run example/main.dart`. Extra arguments are the commands
  to execute first and `-` exits, so `dart run example/main.dart 1 0 -`
  enters menu 1, runs its item 0 and quits (`-h` prints this help, `-v` is
  verbose). Browser: `dart pub global run webdev serve web:8080` (the
  package keeps this in `tool/serve.dart`); reload the page to re-run the
  last item.
* Key values: declare `var apiKey = 'MY_API_KEY'.kvFromVar(defaultValue:
  'demo');` at top level (the value is read when the variable is
  initialized). `kv.key`, `kv.value` (cached), `kv.valid` (non empty),
  `kv.get()` re-reads storage, `await kv.set(value)` stores (`null`
  deletes), `await kv.delete()`. Storage: on io the value is a shell
  environment variable managed by `process_run` (`ShellEnvironment().vars`,
  saved in the project local env file under `.local/`, so a variable
  exported in the shell works too; add `.local/` to `.gitignore`), on the
  web it is `localStorage`. Never bake secrets in the source: read them
  through a key value.
* `keyValuesMenu('vars', [kv1, kv2])` adds a ready made menu to dump,
  prompt (all or only the invalid ones), update and delete each key value.
* Tests: key values also work under `dart test` (`dart_test.yaml` with
  `platforms: [vm, chrome]`); setting one on io spawns `process_run`
  shells, give such tests a long `timeout`.

## Examples

### One menu for the console and the browser

```dart
import 'package:tekartik_app_dev_menu/dev_menu.dart';

var serverUrl = 'DEV_SERVER_URL'.kvFromVar(
  defaultValue: 'http://localhost:8080',
);

Future<void> main(List<String> arguments) async {
  await mainMenu(arguments, () {
    keyValuesMenu('settings', [serverUrl]);
    menu('server', () {
      enter(() => write('using ${serverUrl.get()}'));
      item('ping', () async {
        write('pinging ${serverUrl.value}...');
      });
      item('ask', () async {
        var name = await prompt('Your name then [ENTER]');
        write('hello $name');
      });
      item('crash', () => throw StateError('displayed, menu keeps running'));
      menu('sub', () {
        item('hi', () => writeln('hi from sub'));
      });
    });
  });
}
```

### Persisted settings required by an item

```dart
import 'package:tekartik_app_dev_menu/dev_menu.dart';

var apiKey = 'MY_SERVICE_API_KEY'.kvFromVar();
var projectId = 'MY_SERVICE_PROJECT'.kvFromVar(defaultValue: 'demo');

Future<void> main(List<String> arguments) async {
  await mainMenu(arguments, () {
    keyValuesMenu('vars', [apiKey, projectId]);
    item('call service', () async {
      if (!apiKey.valid) {
        await apiKey.set(await prompt('${apiKey.key} then [ENTER]'));
      }
      write('calling ${projectId.value} with key ${apiKey.value}');
    });
    item('forget key', () async {
      await apiKey.delete();
      write(apiKey); // MY_SERVICE_API_KEY: null
    });
  });
}
```

### Test shaped menu

```dart
import 'package:tekartik_app_dev_menu/test_menu.dart';

Future<void> main(List<String> arguments) async {
  await mainMenu(arguments, () {
    group('math', () {
      test('add', () {
        expect(1 + 1, 2);
      });
      test('async', () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        write('done');
      });
    });
  });
}
```
