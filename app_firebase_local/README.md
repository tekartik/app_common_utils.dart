# tekartik_app_firebase_local

One dependency for a whole local Firebase (no network, no real project): it
has no library of its own, it brings the local implementations of the
tekartik Firebase APIs:

| Package | Brings |
|---|---|
| `tekartik_firebase_local` | the local apps (`newFirebaseMemory()`, `FirebaseLocal`) |
| `tekartik_firebase_firestore_sembast` | Firestore on sembast (`newFirestoreServiceMemory()`) |
| `tekartik_firebase_auth_sembast` | Auth on sembast (`newFirebaseAuthServiceMemory()`) |
| `tekartik_firebase_storage_fs` | Storage on a file system (`newStorageServiceMemory()`) |
| `tekartik_firebase_functions_io` | Functions served on an io http server (`firebaseFunctionsServiceIo`) |

For tests, examples and offline tools on the Dart VM (functions io is Dart VM
only; the other products also run in Flutter and the browser).

## Getting started

Not on pub.dev, add the git dependency:

```yaml
dependencies:
  tekartik_app_firebase_local:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_firebase_local
```

Then import the products from their own packages, all on the same app:

```dart
import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';

Future<void> main() async {
  var app = newFirebaseMemory().initializeApp(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var firestore = newFirestoreServiceMemory().firestore(app);
  var auth = newFirebaseAuthServiceMemory().auth(app);
  var storage = newStorageServiceMemory().storage(app);

  await auth.createUserWithEmailAndPassword(
    email: 'bob@example.com',
    password: 'password1',
  );
  var uid = auth.currentUser!.uid;
  await firestore.doc('users/$uid').set({'name': 'Bob'});
  await storage.bucket('my_bucket').file('$uid/hello.txt').writeAsString('hi');
  print((await firestore.doc('users/$uid').get()).data); // {name: Bob}
  await app.delete();
}
```

[example/main.dart](example/main.dart) adds an http function reading
Firestore, served on a free port.

## Pitfalls

- An app (or package) importing these packages must still list each of them
  in its own `pubspec.yaml` (the `depend_on_referenced_packages` lint, and a
  transitive dependency may go away): the bundle only saves the version
  choice.
- New app code: the sdb backends are the ones to start on,
  `tekartik_firebase_auth_sdb` and `tekartik_firebase_firestore_idb` (on an
  `SdbFactory`), same APIs; the bundle brings their sembast twins.
- Each `newXxxMemory()` service keeps its data in memory: use the same app
  for every product, `await app.delete()` at the end (it closes them).
- Not a backend: no security rules, the functions server is not
  authenticated. See the `tekartik_firebase_local` README for the local
  paths on disk (`FirebaseLocal(localPath: ...)`).
