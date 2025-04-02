import 'dart:convert';
import 'dart:io';

import 'package:cv/cv.dart';

import 'analysis_options_files.dart';

extension AnalysisOptionsFileIo on AnalysisOptionsFile {
  Future<void> read() async {
    final file = File(path);
    try {
      final content = await file.readAsString();
      final options = (jsonDecode(content) as Map).cv<CvAnalysisOptions>(
        builder: (_) => CvAnalysisOptions(),
      );
      this.options = options;
    } on Exception catch (e) {
      print(e);
      rethrow;
    }
  }
}
