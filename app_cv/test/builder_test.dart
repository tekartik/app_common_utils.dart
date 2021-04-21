import 'package:tekartik_app_cv/app_cv.dart';
import 'package:test/test.dart';

class Simple extends CvModelBase {
  final value = CvField<String>('value');

  @override
  List<CvField> get fields => [value];
}

class Parent extends CvModelBase {
  final child = cvModelField<Child>('child');

  @override
  List<CvField> get fields => [child];
}

class Child extends CvModelBase {
  final value = CvField<String>('value');

  @override
  List<CvField> get fields => [value];
}

class ParentWithList extends CvModelBase {
  final children = cvModelListField<Child>('children');

  @override
  List<CvField> get fields => [children];
}

void initModelBuilders() {
  cvAddBuilder<Parent>((_) => Parent());
  cvAddBuilder<Child>((_) => Child());
  cvAddBuilder<Simple>((_) => Simple());
  cvAddBuilder<ParentWithList>((_) => ParentWithList());
}

void main() {
  initModelBuilders();
  group('builder', () {
    test('simple', () {
      var simple = {'value': 'test'}.cv<Simple>();
      expect(simple.value.v, 'test');
    });
    test('cvModelField', () async {
      var parent = Parent()..child.v = (Child()..value.v = 'test');
      expect(parent.toModel(), {
        'child': {'value': 'test'}
      });
      expect(parent.toModel().cv<Parent>(), parent);
    });
    test('cvModelListField', () async {
      var parent = ParentWithList()..children.v = [Child()..value.v = 'test'];
      expect(parent.toModel(), {
        'children': [
          {'value': 'test'}
        ]
      });
      expect(parent.toModel().cv<ParentWithList>(), parent);
    });
  });
}
