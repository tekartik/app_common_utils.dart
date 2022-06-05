import 'package:cv/cv.dart';
class CvAnalysisOptions extends CvModelBase {
  @override
  List<CvField> get fields => [];

}
class AnalysisOptionsFile  {
  final String path;

  // Valid after a successfull read
    late CvAnalysisOptions options;
  AnalysisOptionsFile(this.path)  ;
}