import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:tekartik_app_csv/app_csv.dart';
import 'package:test/test.dart';

void expectCsv(String value, String expected) {
  expect(const LineSplitter().convert(value),
      const LineSplitter().convert(expected));
}

void main() {
  group('src_csv_utils', () {
    group('csvToMapList', () {
      test('null', () {
        expect(csvToMapList('''
null,test\r
,1\r
'''), [
          {'null': '', 'test': 1}
        ]);
      });
      test('empty', () {
        expect(csvToMapList('''
test
'''), isEmpty);
      });
      test('simple', () {
        expect(csvToMapList('''
test\r
1
'''), [
          {'test': 1}
        ]);
      });
      test('2 lines', () {
        expect(csvToMapList('''
test\r
1\r
2
'''), [
          {'test': 1},
          {'test': 2}
        ]);
      });
      test('all', () {
        expect(csvToMapList('''
int,double,String,bool,Uint8List\r
1,2.1,text,true,"[1, 2, 3]"\r
'''), [
          {
            'int': 1,
            'double': 2.1,
            'String': 'text',
            'bool': 'true',
            'Uint8List': '[1, 2, 3]'
          }
        ]);
      });
      test('line feed', () {
        var csv = 'one_column_with_line_feed\r\n"Hello\nWorld"';
        expect(
            csvToMapList(csv,
                converter: CsvToListConverter(fieldDelimiter: ',')),
            [
              {'one_column_with_line_feed': 'Hello\nWorld'}
            ]);
        var mapList = csvToMapList(csv);
        expect(mapList, [
          {'one_column_with_line_feed': 'Hello\nWorld'}
        ]);
        expect(mapListToCsv(mapList), csv);
      });
    });
    group('mapListToCsv', () {
      test('null', () {
        expectCsv(
            mapListToCsv([
              {'null': null, 'test': 1}
            ]),
            '''
null,test
,1
''');
        expectCsv(
            mapListToCsv([
              {'null': null, 'test': 1}
            ], nullValue: null),
            '''
null,test
null,1
''');
      });
      test('mapListToCsv missing', () {
        expectCsv(
            mapListToCsv([
              {'test1': 1},
              {'test2': 2}
            ]),
            '''
test1,test2
1,
,2
''');
        expectCsv(
            mapListToCsv([
              {'test1': 1},
              {'test2': 2}
            ], nullValue: null),
            '''
test1,test2
1,null
null,2
''');
      });
      test('mapListToCsv columns', () {
        expectCsv(
            mapListToCsv([
              {'test1': 1},
            ], columns: [
              'test2'
            ]),
            '''
test2,test1
,1
''');
      });
      test('mapListToCsv', () {
        // empty
        expect(mapListToCsv(<Map<String, Object?>>[]), '');

        // simple
        expectCsv(
            mapListToCsv([
              {'test': 1}
            ]),
            '''
test
1
''');

        // all types
        expectCsv(
            mapListToCsv([
              {
                'int': 1,
                'double': 2.1,
                'String': 'text',
                'bool': true,
                'Uint8List': Uint8List.fromList([1, 2, 3])
              }
            ]),
            '''
int,double,String,bool,Uint8List
1,2.1,text,true,"[1, 2, 3]"
''');
      });
    });
    test('test_eol', () async {
      var csv = 'a,b\r\n1,2';
      expect(csvToMapList(csv), [
        {'a': 1, 'b': 2}
      ]);
      csv = 'a,b\r\n1,2\r\n';
      expect(csvToMapList(csv), [
        {'a': 1, 'b': 2}
      ]);
      expect(csvToMapList(csv), [
        {'a': 1, 'b': 2}
      ]);
      csv = 'a,b\n1,2';
      expect(csvToMapList(csv, converter: CsvToListConverter()), isEmpty);
      expect(csvToMapList(csv), [
        {'a': 1, 'b': 2}
      ]);
      expect(csvToMapList(csv, converter: CsvToListConverter(eol: '\n')), [
        {'a': 1, 'b': 2}
      ]);
    });
    test('test_quotes', () async {
      var csv =
          '''Id question,Question FR,Question EN,Resp.A. FR,Resp.A. EN,Resp.B. FR,Resp.B. EN,Resp.C. FR,Resp.C EN,Bonne réponse
2,Quel joueur détient le record du nombre d'essais marqués en Coupe du monde de rugby ?,Which player holds the record for the most tries scored in the Rugby World Cup?,Bryan Habana,Bryan Habana,Jonah Lomu,Jonah Lomu,Jonny Wilkinson,Jonny Wilkinson,B
4,Dans quel pays se déroule traditionnellement le tournoi des Tri-Nations ?,In which country is the Tri-Nations tournament traditionally held?,"Australie, Nouvelle-Zélande, Afrique du Sud","Australia, New Zealand, South Africa","Angleterre, Ecosse, Pays de Galles","England, Scotland, Wales","Irlande, France, Italie","Ireland, France, Italy",A
5,Quel est le poste d’Antoine Dupont en équipe de France ?,What is Antoine Dupont’s position in the French team?,Centre,Center,Troisième ligne aile,Third line wing,Demi de mêlée,Scrum-half,C
''';
      var converter = CsvToListConverter(
          csvSettingsDetector: FirstOccurrenceSettingsDetector(eols: [
        '\r\n',
        '\n'
      ], textDelimiters: [
        '"',
      ]));
      expect(csvToMapList(csv, converter: converter), [
        {'a': 1, 'b': '2,3'}
      ]);
    });
    test('separator', () {
      expect(
          mapListToCsv([
            {'test': 1}
          ]),
          'test\r\n1');
    });
    test('gsheet', () {
      var csv = 'one_column_with_line_feed\r\n'
          '"Hello\n'
          'World"';
      expect(csvToMapList(csv), [
        {'one_column_with_line_feed': 'Hello\nWorld'}
      ]);
      // bad
      csv = 'one_column_with_line_feed\n'
          '"Hello\n'
          'World"';
      expect(csvToMapList(csv, converter: CsvToListConverter()), isEmpty);
      expect(csvToMapList(csv), [
        {
          'one_column_with_line_feed': 'Hello\n'
              'World'
        }
      ]);
    });
  });
}
