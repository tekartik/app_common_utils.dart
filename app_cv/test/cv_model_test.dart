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
  final value = CvField<int>('value');

  @override
  List<CvField> get fields => [value];
}

class Custom {
  final String value;

  Custom(this.value);
  @override
  String toString() => value;

  @override
  int get hashCode => value.hashCode;
  @override
  bool operator ==(Object other) {
    return other is Custom && (other.value == value);
  }
}

class CustomContent extends CvModelBase {
  final custom1 = CvField<Custom>('custom1');
  final custom2 = CvField<Custom>('custom2');
  final text = CvField<String>('text');
  @override
  List<CvField> get fields => [
        custom1,
        custom2,
        text,
      ];
}

class StringContent extends CvModelBase {
  final value = CvField<String>('value');

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
      expect(IntContent().toModel(includeMissingValue: true), {'value': null});
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
    test('fromModel1', () async {
      var content = IntContent()..fromModel({});
      expect(content.value.hasValue, false);
      expect(content.value.v, null);
      content = IntContent()..fromModel({'value': null});
      expect(content.value.hasValue, true);
      expect(content.value.v, null);
      content = IntContent()..fromMap({'value': null});
      expect(content.value.hasValue, true);
      expect(content.value.v, null);

      // Bad type
      content = IntContent()..fromMap({'value': 'not an int'});
      expect(content.value.hasValue, false);
      expect(content.value.v, null);
      // Bad type, ok for string
      var stringContent = StringContent()..fromMap({'value': 12});
      expect(stringContent.value.hasValue, true);
      expect(stringContent.value.v, '12');
    });
    test('fromModel2', () async {
      expect(IntContent()..fromModel({}), IntContent());
      expect(IntContent()..fromModel({'value': 1}), IntContent()..value.v = 1);
      expect(
          IntContent()
            ..fromModel({'value': 1}, columns: [IntContent().value.name]),
          IntContent()..value.v = 1);
      expect(IntContent()..fromModel({'value': 1}, columns: []), IntContent());
    });
    test('copyFrom', () {
      var cv = IntContent()..copyFrom(IntContent());
      expect(cv.toModel(), {});
      cv = IntContent()..copyFrom(IntContent()..value.v = null);
      expect(cv.toModel(), {'value': null});
      cv = IntContent()..copyFrom(IntContent()..value.v = 1);
      expect(cv.toModel(), {'value': 1});

      var src = CvMapModel();
      src['value'] = 1;
      expect(src.toModel(), {'value': 1});
      cv = IntContent()..copyFrom(src);
      expect(cv.toModel(), {'value': 1});

      src = CvMapModel();
      src['test'] = 1;
      expect(src.toModel(), {'test': 1});
      cv = IntContent()..copyFrom(src);
      expect(cv.toModel(), {});
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
      expect(WithChildCvField().toModel(), {});
      expect(WithChildCvField().toModel(includeMissingValue: true),
          {'child': null});
      expect(
          (WithChildCvField()..child.v = ChildContent())
              .toModel(includeMissingValue: true),
          {
            'child': {'sub': null}
          });
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
      expect(WithChildListCvField().toModel(), {});
      expect(WithChildListCvField().toModel(includeMissingValue: true),
          {'children': null});

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

    test('fillModel', () {
      expect(
          (CvModelField<IntContent>('int', (_) => IntContent())
                ..fillModel(CvFillOptions(valueStart: 0)))
              .v,
          IntContent()..value.v = 1);
    });

    test('fillModelList', () {
      expect(
          (CvModelListField<IntContent>('int', (_) => IntContent())
                ..fillList(CvFillOptions(collectionSize: 1, valueStart: 0)))
              .v,
          [IntContent()..value.v = 1]);
    });

    test('fillModel', () {
      expect((IntContent()..fillModel()).toModel(), {'value': null});
      expect((WithChildCvField()..fillModel()).toModel(), {
        'child': {'sub': null}
      });
      expect(
          (WithChildListCvField()..fillModel()).toModel(), {'children': null});
      expect((AllTypes()..fillModel()).toModel(), {
        'bool': null,
        'int': null,
        'num': null,
        'string': null,
        'children': null,
        'intList': null,
        'map': null,
        'mapList': null
      });
    });
    test('fillModel', () {
      expect((IntContent()..fillModel(CvFillOptions(valueStart: 0))).toModel(),
          {'value': 1});
      expect(
          (WithChildCvField()..fillModel(CvFillOptions(valueStart: 0)))
              .toModel(),
          {
            'child': {'sub': 'text_1'}
          });
      expect(
          (WithChildListCvField()
                ..fillModel(CvFillOptions(valueStart: 0, collectionSize: 1)))
              .toModel(),
          {
            'children': [
              {'sub': 'text_1'}
            ]
          });
      expect(
          (AllTypes()
                ..fillModel(CvFillOptions(valueStart: 0, collectionSize: 1)))
              .toModel(),
          {
            'bool': false,
            'int': 2,
            'num': 3.5,
            'string': 'text_4',
            'children': [
              {
                'child': {'sub': 'text_5'}
              }
            ],
            'intList': [6],
            'map': null,
            'mapList': [
              {'field_0': 7}
            ]
          });
      expect(
          (CustomContent()
                ..fillModel(CvFillOptions(
                    valueStart: 0,
                    collectionSize: 1,
                    generate: (type, options) {
                      if (type == Custom) {
                        if (options.valueStart != null) {
                          var value =
                              options.valueStart = options.valueStart! + 1;
                          return Custom('custom_$value');
                        }
                      }
                      return null;
                    })))
              .toModel(),
          {
            'custom1': Custom('custom_1'),
            'custom2': Custom('custom_2'),
            'text': 'text_3'
          });
    });
    test('custom', () {
      expect((CustomContent()..custom1.v = Custom('test')).toModel(),
          {'custom1': Custom('test')});
    });
    test('CvFieldWithParent', () {
      var object = WithCvFieldWithParent();
      expect(object.fields.map((e) => e.name), ['sub.value', 'sub.value2']);
      expect((WithCvFieldWithParent()..value.v = 1).toModel(), {
        'sub': {'value': 1}
      });
      expect(
          (WithCvFieldWithParent()
                ..value.v = 1
                ..value2.v = 2)
              .toModel(),
          {
            'sub': {'value': 1, 'value2': 2}
          });
      expect((WithCvFieldWithParent()..value.v = null).toModel(), {
        'sub': {'value': null}
      });
      expect(WithCvFieldWithParent().toModel(), {});

      var field = WithCvFieldWithParent()
        ..fromModel({
          'sub': {'value': 1}
        });
      expect(field.value.v, 1);
      expect(field.toModel(), {
        'sub': {'value': 1}
      });

      expect(
          (WithCvFieldWithParent()
                ..fillModel(CvFillOptions(valueStart: 0, collectionSize: 1)))
              .toModel(),
          {
            'sub': {'value': 1, 'value2': 2}
          });
    });
  });
}

class WithDuplicatedCvFields extends CvModelBase {
  final cvField1 = CvField<String>('CvField1');
  final cvField2 = CvField<String>('CvField1');

  @override
  List<CvField> get fields => [cvField1, cvField2];
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

class WithCvFieldWithParent extends CvModelBase {
  final value = CvField<int>('value').withParent('sub');
  final value2 = CvField<int>('value2').withParent('sub');

  @override
  List<CvField> get fields => [value, value2];
}

class ChildContent extends CvModelBase {
  final sub = CvField<String>('sub');

  @override
  List<CvField> get fields => [sub];
}

class AllTypes extends CvModelBase {
  final boolCvField = CvField<bool>('bool');
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
        boolCvField,
        intCvField,
        numCvField,
        stringCvField,
        children,
        intListCvField,
        mapCvField,
        mapListCvField
      ];
}
