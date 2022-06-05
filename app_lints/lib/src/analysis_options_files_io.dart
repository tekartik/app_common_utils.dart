import 'dart:convert';
import 'dart:io';

import 'analysis_options_files.dart';

extension AnalysisOptionsFileIo on AnalysisOptionsFile {
  Future<void> read() async {
    final file = File(path);
    try {
    final content = await file.readAsString();
      final map = jsonDecode(content);
      if (options != null) {
        this.options = options;
      }
    } on Exception catch (e) {
      //print(e);
      rethrow;
    }
  }
}