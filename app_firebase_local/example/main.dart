import 'dart:convert';
import 'dart:io';

import 'package:tekartik_firebase_auth_sembast/auth_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_functions_io/firebase_functions_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';

/// A whole local Firebase in one process, in memory: Firestore, Auth and
/// Storage on one app, and an http function served on a free port.
Future<void> main() async {
  var app = newFirebaseMemory().initializeApp(
    options: FirebaseAppOptions(projectId: 'my-project'),
  );
  var firestore = newFirestoreServiceMemory().firestore(app);
  var auth = newFirebaseAuthServiceMemory().auth(app);
  var storage = newStorageServiceMemory().storage(app);
  var functions = firebaseFunctionsServiceIo.functions(app);

  await auth.createUserWithEmailAndPassword(
    email: 'bob@example.com',
    password: 'password1',
  );
  var uid = auth.currentUser!.uid;
  await firestore.doc('users/$uid').set({'name': 'Bob'});
  await storage.bucket('my_bucket').file('$uid/hello.txt').writeAsString('hi');

  // An http function reading Firestore.
  functions['userName'] = functions.https.onRequest((request) async {
    var id = request.uri.queryParameters['uid'];
    var snapshot = await firestore.doc('users/$id').get();
    await request.response.send(snapshot.data['name'] as String?);
  });
  var server = await functions.serveHttp(port: 0);
  var uri = httpServerGetUri(
    server,
  ).replace(path: '/userName', queryParameters: {'uid': uid});
  var client = HttpClient();
  var response = await (await client.getUrl(uri)).close();
  print(await utf8.decodeStream(response)); // Bob
  client.close();

  await server.close();
  await app.delete();
}
