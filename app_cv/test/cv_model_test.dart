import 'package:tekartik_app_cv/app_cv.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:test/test.dart';

class Note extends CvModelBase {
  final title = CvField<String>('title');
  final content = CvField<String>('content');
  final date = CvField<int>('date');

  @override
  List<CvField> get fields => [title, content, date];
}

class IntContent extends CvModelBase {
  final value = CvField<int?>('value');

  @override
  List<CvField> get fields => [value];
}

void main() {
  group('cv', () {
    test('CvModel', () {
      var model = CvMapModel();
      model['test'] = 1;
    });
    test('equals', () {
      expect(IntContent(), IntContent());
      expect(IntContent()..value.v = 1, IntContent()..value.v = 1);
      expect(IntContent(), isNot(IntContent()..value.v = 1));
      expect(IntContent()..value.v = 2, isNot(IntContent()..value.v = 1));
    });
    test('toModel', () async {
      expect(IntContent().toModel(), {});
      expect((IntContent()..value.v = 1).toModel(), {'value': 1});
      expect((IntContent()..value.v = 1).toMap(), {'value': 1});
      expect((IntContent()..value.v = 1).toModel(columns: <String>[]), {});
      expect(
          (IntContent()..value.v = 1).toModel(columns: [IntContent().value.k]),
          {'value': 1});
    });
    test('toModel', () async {
      expect(IntContent().toModel(), {});
      expect((IntContent()..value.v = 1).toModel(), {'value': 1});
      expect((IntContent()..value.v = null).toModel(), {'value': null});
      expect((IntContent()..value.setNull()).toModel(), {'value': null});
      expect((IntContent()..value.setValue(null)).toModel(), {});
      expect(
          (IntContent()..value.setValue(null, presentIfNull: true)).toModel(),
          {'value': null});
    });
    test('fromModel', () async {
      var content = IntContent()..fromModel({});
      expect(content.value.hasValue, false);
      expect(content.value.v, null);
      content = IntContent()..fromModel({'value': null});
      expect(content.value.hasValue, true);
      expect(content.value.v, null);
      content = IntContent()..fromMap({'value': null});
      expect(content.value.hasValue, true);
      expect(content.value.v, null);
    });
    test('fromModel', () async {
      expect(IntContent()..fromModel({}), IntContent());
      expect(IntContent()..fromModel({'value': 1}), IntContent()..value.v = 1);
      expect(
          IntContent()
            ..fromModel({'value': 1}, columns: [IntContent().value.name]),
          IntContent()..value.v = 1);
      expect(IntContent()..fromModel({'value': 1}, columns: []), IntContent());
    });
    test('alltoModel', () async {
      var note = Note()
        ..title.v = 'my_title'
        ..content.v = 'my_content'
        ..date.v = 1;
      expect(note.toModel(),
          {'title': 'my_title', 'content': 'my_content', 'date': 1});
      expect(note.toModel(columns: [note.title.name]), {'title': 'my_title'});
    });
    test('duplicated CvField', () {
      try {
        WithDuplicatedCvFields().toModel();
        fail('should fail');
      } on UnsupportedError catch (e) {
        print(e);
      }
      try {
        WithDuplicatedCvFields().fromModel({});
        fail('should fail');
      } on UnsupportedError catch (e) {
        print(e);
      }
      try {
        WithDuplicatedCvFields().copyFrom(CvMapModel());
        fail('should fail');
      } on UnsupportedError catch (e) {
        print(e);
      }
    });
    test('content child', () {
      var parent = WithChildCvField()
        ..child.v = (ChildContent()..sub.v = 'sub_value');
      var map = {
        'child': {'sub': 'sub_value'}
      };
      expect(parent.toModel(), map);
      parent = WithChildCvField()..fromModel(map);
      expect(parent.toModel(), map);
    });
    test('content child list', () {
      var parent = WithChildListCvField()
        ..children.v = [ChildContent()..sub.v = 'sub_value'];
      var map = {
        'children': [
          {'sub': 'sub_value'}
        ]
      };
      expect(parent.children.v!.first.sub.v, 'sub_value');
      expect(parent.toModel(), map);
      parent = WithChildListCvField()..fromModel(map);
      expect(parent.toModel(), map);
    });
    test('all types', () {
      AllTypes? allTypes;
      void _check() {
        var export = allTypes!.toModel();
        var import = AllTypes()..fromModel(export);
        expect(import, allTypes);
        expect(import.toModel(), allTypes.toModel());
        import = AllTypes()..fromModel(jsonDecode(jsonEncode(export)) as Map);

        expect(import.toModel(), allTypes.toModel());
      }

      allTypes = AllTypes();
      _check();
      allTypes
        ..intCvField.v = 1
        ..numCvField.v = 2.5
        ..stringCvField.v = 'some_test'
        ..intListCvField.v = [2, 3, 4]
        ..mapCvField.v = {'sub': 'map'}
        ..mapListCvField.v = [
          {'sub': 'map'}
        ]
        ..children.v = [
          WithChildCvField()..child.v = (ChildContent()..sub.v = 'sub_value')
        ];
      _check();
    });
  });
}

class WithDuplicatedCvFields extends CvModelBase {
  final CvField1 = CvField<String>('CvField1');
  final CvField2 = CvField<String>('CvField1');

  @override
  List<CvField> get fields => [CvField1, CvField2];
}

class WithChildCvField extends CvModelBase {
  final child = CvModelField<ChildContent>('child', (_) => ChildContent());

  @override
  List<CvField> get fields => [child];
}

class WithChildListCvField extends CvModelBase {
  final children =
      CvModelListField<ChildContent>('children', (_) => ChildContent());

  @override
  List<CvField> get fields => [children];
}

class ChildContent extends CvModelBase {
  final sub = CvField<String>('sub');

  @override
  List<CvField> get fields => [sub];
}

class AllTypes extends CvModelBase {
  final intCvField = CvField<int>('int');
  final numCvField = CvField<num>('num');
  final stringCvField = CvField<String>('string');
  final intListCvField = CvListField<int>('intList');
  final mapCvField = CvField<Map>('map');
  final mapListCvField = CvListField<Map>('mapList');
  final children =
      CvModelListField<WithChildCvField>('children', (_) => WithChildCvField());

  @override
  List<CvField> get fields => [
        intCvField,
        numCvField,
        stringCvField,
        children,
        intListCvField,
        mapCvField,
        mapListCvField
      ];
}