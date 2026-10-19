import 'dart:convert';
import 'dart:io';

import 'package:excel_plus/excel_plus.dart';

const _bookmarkHeaders = <String>[
  'title',
  'url',
  'description',
  'tags',
  'imageUrls',
  'videoUrl',
  'collection',
];

const _bookmarkRows = <List<Object?>>[
  [
    'Dart',
    'https://dart.dev',
    'الموقع الرسمي للغة Dart',
    'dart;برمجة',
    '',
    '',
    'Development',
  ],
  [
    'Flutter',
    'https://flutter.dev',
    'الموقع الرسمي لإطار Flutter',
    'flutter;mobile',
    '',
    '',
    'Development',
  ],
  [
    'OpenAI',
    'https://openai.com',
    'مصدر عن الذكاء الاصطناعي',
    'ai;research',
    '',
    '',
    'Research',
  ],
  [
    'ويكيبيديا العربية',
    'https://ar.wikipedia.org',
    'موسوعة عربية حرة',
    'عربي;معرفة',
    '',
    '',
    'مراجع',
  ],
];

const _collectionHeaders = <String>[
  'name',
  'icon',
  'color',
  'bookmarkIds',
];

const _collectionRows = <List<Object?>>[
  ['Development', 'code', 4280391411, ''],
  ['Research', 'science', 4283215696, ''],
  ['مراجع', 'book', 4293212469, ''],
];

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/generate_import_samples.dart <dir>');
    exitCode = 64;
    return;
  }

  final output = Directory(arguments.single)..createSync(recursive: true);
  _writeCsv(
    File('${output.path}/bookmarks_sample.csv'),
    _bookmarkHeaders,
    _bookmarkRows,
  );
  _writeJson(
    File('${output.path}/bookmarks_sample.json'),
    _bookmarkHeaders,
    _bookmarkRows,
  );
  _writeXlsx(
    File('${output.path}/bookmarks_sample.xlsx'),
    _bookmarkHeaders,
    _bookmarkRows,
  );

  _writeCsv(
    File('${output.path}/collections_sample.csv'),
    _collectionHeaders,
    _collectionRows,
  );
  _writeJson(
    File('${output.path}/collections_sample.json'),
    _collectionHeaders,
    _collectionRows,
  );
  _writeXlsx(
    File('${output.path}/collections_sample.xlsx'),
    _collectionHeaders,
    _collectionRows,
  );

  File('${output.path}/README_AR.txt').writeAsStringSync(
    'ملفات تجربة الاستيراد\n'
    '=======================\n\n'
    '1. اختر صيغة واحدة فقط من ملفات collections_sample واستوردها من شاشة المجموعات.\n'
    '2. اختر صيغة واحدة فقط من ملفات bookmarks_sample واستوردها من شاشة الإشارات.\n'
    '3. استخدم سياسة Skip عند تكرار التجربة، أو Update لاختبار التحديث.\n\n'
    'ملفات CSV وJSON وXLSX في كل مجموعة تحتوي البيانات نفسها؛ '
    'وهي بدائل لا ملفات متتابعة.\n',
    encoding: utf8,
  );
}

void _writeCsv(
  File file,
  List<String> headers,
  List<List<Object?>> rows,
) {
  final lines = <String>[
    headers.map(_csvCell).join(','),
    for (final row in rows) row.map(_csvCell).join(','),
  ];
  file.writeAsStringSync('${lines.join('\r\n')}\r\n', encoding: utf8);
}

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  if (!text.contains(RegExp('[,"\r\n]'))) return text;
  return '"${text.replaceAll('"', '""')}"';
}

void _writeJson(
  File file,
  List<String> headers,
  List<List<Object?>> rows,
) {
  final records = [
    for (final row in rows)
      <String, Object?>{
        for (var index = 0; index < headers.length; index++)
          headers[index]: row[index],
      },
  ];
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(records)}\n', encoding: utf8);
}

void _writeXlsx(
  File file,
  List<String> headers,
  List<List<Object?>> rows,
) {
  final workbook = Excel.createExcel();
  final sheet = workbook[workbook.getDefaultSheet()!];
  sheet.isRTL = true;
  sheet.appendRow(headers.map(TextCellValue.new).toList());
  for (final row in rows) {
    sheet.appendRow(row.map(_excelCell).toList());
  }
  final bytes = workbook.save();
  if (bytes == null) throw StateError('Could not encode ${file.path}');
  file.writeAsBytesSync(bytes);
}

CellValue _excelCell(Object? value) => switch (value) {
  final int number => IntCellValue(number),
  null => TextCellValue(''),
  _ => TextCellValue(value.toString()),
};
