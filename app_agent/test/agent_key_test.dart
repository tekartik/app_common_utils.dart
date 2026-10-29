@TestOn('vm')
library;

import 'dart:io';
import 'dart:math';

import 'package:tekartik_app_agent/agent_constants_io.dart';
import 'package:tekartik_app_agent/app_agent.dart';
import 'package:test/test.dart';

void main() {
  test('key', () {
    var text = AgentKey.generate(Random(1));
    expect(text, hasLength(32));
    expect(Uri.encodeQueryComponent(text), text);
    expect(AgentKey.generate(), isNot(AgentKey.generate()));
    var key = AgentKey.hashed(AgentKey.hashOf(text));
    expect(key.matches(text), isTrue);
    expect(key.matches('$text.'), isFalse);
    expect(key.matches(''), isFalse);
    expect(key.matches(null), isFalse);
    expect('$key', 'AgentKey(***)');
    expect(AgentKey.hashOf(text), isNot(contains(text)));
  });

  test('agentAllowed', () {
    var text = AgentKey.generate();
    var key = AgentKey.hashed(AgentKey.hashOf(text));
    AgentUrlOptions options(String url) =>
        AgentUrlOptions.fromUri(Uri.parse(url));

    // Not a release build: ?agent is enough.
    expect(options('/?agent').agentAllowed(release: false), isTrue);
    expect(options('/').agentAllowed(release: false), isFalse);
    // A release build: the key, read only with ?agent.
    var reads = 0;
    AgentKey readKey() {
      reads++;
      return key;
    }

    expect(
      options('/').agentAllowed(release: true, releaseKey: readKey),
      isFalse,
    );
    expect(reads, 0);
    expect(
      options('/?agent').agentAllowed(release: true, releaseKey: readKey),
      isFalse,
    );
    expect(
      options('/?agent=wrong').agentAllowed(release: true, releaseKey: readKey),
      isFalse,
    );
    expect(
      options('/?agent=$text').agentAllowed(release: true, releaseKey: readKey),
      isTrue,
    );
    expect(
      options(
        '/#/home?agent=$text',
      ).agentAllowed(release: true, releaseKey: readKey),
      isTrue,
    );
    expect(reads, 4);
    // No key for the app: ?agent is enough in a release build too.
    expect(options('/?agent').agentAllowed(release: true), isTrue);
    expect(
      options('/?agent').agentAllowed(release: true, releaseKey: () => null),
      isTrue,
    );
    expect(options('/').agentAllowed(release: true), isFalse);
    expect('${options('/?agent=$text')}', isNot(contains(text)));
  });

  test('agent constants', () async {
    const apps = [
      AgentKeyApp(
        name: 'orga',
        title: 'Festen Orga',
        urls: ['https://example.com/orga/', 'https://example.com/?a=1#/'],
      ),
      AgentKeyApp(name: 'admin', title: 'Admin'),
    ];
    var dir = await Directory.systemTemp.createTemp('agent_constants_');
    try {
      var path = '${dir.path}/lib/src/agent_constants.dart';
      var content = await agentConstantsGenerate(apps, path: path);
      var keys = agentConstantsKeys(content);
      expect(keys.keys, ['orga', 'admin']);
      var orga = keys['orga']!;
      expect(content, contains('https://example.com/orga/?agent=$orga'));
      expect(content, contains('https://example.com/?a=1&agent=$orga#/'));
      expect(content, contains(AgentKey.hashOf(orga)));
      expect(content, contains('@internal'));
      // Generated again: the same keys; renewed: new ones.
      expect(
        agentConstantsKeys(await agentConstantsGenerate(apps, path: path)),
        keys,
      );
      expect(
        agentConstantsKeys(
          await agentConstantsGenerate(apps, path: path, renew: true),
        )['orga'],
        isNot(orga),
      );
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
