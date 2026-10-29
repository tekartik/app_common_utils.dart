---
name: tekartik-app-agent
description: >-
  Use when making a Flutter web app drivable by an agent (an LLM with a
  browser, a headless Chrome check, Playwright) or writing such a check, with
  tekartik_app_agent: AgentUrlOptions.fromUri (?semantics, ?agent, also in a
  hash url fragment), AgentWebPage(evaluate) (ids, has, waitFor, text, tap,
  location, waitForLocation, back) over the flt-semantics-identifier
  attributes.
---

# Agent helpers (tekartik_app_agent)

Pure Dart: usable from a tool (VM) and from an app (web). The Flutter widgets
are in `tekartik_app_agent_flutter` (`AgentId`, `agentInit`).

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_agent:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_agent
  ```
* `AgentUrlOptions.fromUri(Uri.base)` reads `semantics` and `agent` from the
  query and from the query of a hash fragment (`/#/home?agent`). A parameter
  is on when present (empty or any value but `0`, `false`, `no`, `off`).
  `needsSemantics` is `semantics || agent`.
* A Flutter web app only builds its semantics DOM (where the ids live) once
  asked: the app calls `agentInit()` (tekartik_app_agent_flutter) at start,
  and the url carries `?semantics` or `?agent`.
* `AgentWebPage(evaluate)` takes any `Future<Object?> Function(String js)`
  returning json values (CDP `Runtime.evaluate` with `returnByValue`,
  Playwright `page.evaluate`). Ids are looked up as
  `[flt-semantics-identifier="<id>"]`, json-escaped.
* `waitFor(id, others:, timeout:)` throws a `TimeoutException` listing the
  missing ids and the ids on screen: the message is the debugging aid.
* `tap(id)` clicks the semantics node: the Flutter tap of the widget whose
  `Semantics(identifier:)` is merged with its action (`AgentId` does it).
* `location()` is `location.pathname + location.hash` (hash url apps put
  their route in the hash).

## Example

```dart
import 'package:tekartik_app_agent/app_agent.dart';

Future<void> checkHome(AgentEvaluate evaluate) async {
  var page = AgentWebPage(evaluate);
  await page.waitFor('nav-program', others: ['nav-artists']);
  await page.tap('nav-artists');
  await page.waitForLocation('/artists');
  print(await page.ids());
}
```
