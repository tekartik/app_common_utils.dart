import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast/unique_index.dart';

/// our book store
var bookStore = intMapStoreFactory.store('book');

/// Our index on the `code` field which is a String
var codeIndex = bookStore.index<String>('code');

/// Our life time index. Declare globally to access from anywhere if the database
/// remains open.
late DatabaseIndex<String, int> dbCodeIndex;

Future<void> main() async {
  var db = await databaseFactoryMemory.openDatabase('test.db');

  // Create our db active index.
  dbCodeIndex = db.index(codeIndex, throwOnConflict: true);

  await bookStore.addAll(db, [
    {'code': 'BOOK001', 'title': 'The great book'},
    {'code': 'BOOK002', 'title': 'The simple book'},
  ]);

  /// Access a book by code
  var book = (await dbCodeIndex.record('BOOK001').getSnapshot())!;

  /// Should print the great book!
  print(book['title']);

  /// You can also read in a transaction.
  await db.transaction((transaction) async {
    /// Access a book by code
    var book =
        (await dbCodeIndex
            .transactionRecord(transaction, 'BOOK002')
            .getSnapshot())!;

    /// Should print the simple book!
    print(book['title']);
  });

  // Dispose the index and close the database
  // In a regular application, you might keep them open forever!
  dbCodeIndex.dispose();
  await db.close();
}
