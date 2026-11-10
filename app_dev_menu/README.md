# tekartik_app_dev_menu

One developer / manual test menu for the console and the browser: declare
menus and items once, run them with `dart run` (a numbered menu on
stdin/stdout) or in a web page (a clickable menu with an output panel).
Settings (urls, ids, keys) are kept in key values: shell environment
variables on io (process_run, saved in `.local/`), `localStorage` on the
web.

It bundles `tekartik_test_menu`, `tekartik_test_menu_io` and
`tekartik_test_menu_browser` behind one import. For a Flutter app, see
`tekartik_app_dev_menu_flutter`.

## Getting started

```yaml
dependencies:
  tekartik_app_dev_menu:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_dev_menu
```

A `main.dart` for both platforms:

```dart
import 'package:tekartik_app_dev_menu/dev_menu.dart';

var serverUrl = 'DEV_SERVER_URL'.kvFromVar(
  defaultValue: 'http://localhost:8080',
);

Future<void> main(List<String> arguments) async {
  await mainMenu(arguments, () {
    keyValuesMenu('settings', [serverUrl]);
    menu('server', () {
      item('ping', () async {
        write('pinging ${serverUrl.value}');
      });
      item('ask', () async {
        var name = await prompt('Your name');
        write('hello $name');
      });
    });
  });
}
```

- Console: `dart run main.dart`, type the number of an entry, `.` goes back
  (and exits from the top menu), `?` shows the menu again. Arguments are
  typed first: `dart run main.dart 1 0 . .` opens menu 1, runs its item 0
  and exits.
- Browser: the same `main.dart` in `web/` with an `index.html` loading
  `main.dart.js`, `dart pub global run webdev serve web:8080` (needs
  `build_runner` and `build_web_compilers` as dev dependencies). Reloading
  the page runs the last item again.

The package's own [example](example/main.dart).

## API

- `mainMenu(arguments, declare)`: the entry point (console or browser).
  `declare` is synchronous and only declares; item bodies may be async.
- `menu(name, body)`, `item(name, body)`, `enter`/`leave` (hooks of a
  menu), `write`/`writeln` (shown in the browser panel too, unlike `print`),
  `await prompt('question')`.
- Key values: `var kv = 'KEY'.kvFromVar(defaultValue: ...)` at top level;
  `kv.value` (read at creation), `kv.valid` (not empty), `kv.get()` (read
  again), `await kv.set(value)` (`null` deletes), `await kv.delete()`;
  `keyValuesMenu(name, [kv, ...])` adds a menu to show, prompt and delete
  them.
- `package:tekartik_app_dev_menu/test_menu.dart` adds `test`, `group`,
  `expect` for test shaped menus.

## Pitfalls

- Never write a secret in the source: read it through a key value. On io
  it is saved in the project `.local/` folder: git-ignore `.local/`.
- Browsers ask for a user gesture before audio, clipboard, popups: run such
  code from an item, not from `main`.
- `solo_item` / `solo_menu` (run one entry only) are for local debugging:
  never commit them.

More in the [package skill](skills/tekartik-app-dev-menu-setup/SKILL.md).
