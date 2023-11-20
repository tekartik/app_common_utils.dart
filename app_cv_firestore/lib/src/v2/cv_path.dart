abstract class CvPathReference {
  String get path;
}

mixin CvPathReferenceMixin implements CvPathReference {
  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is CvPathReference) {
      return path == other.path;
    }
    return false;
  }
}
