import 'package:document_engine/document_engine.dart';
import 'package:test/test.dart';

void main() {
  group('DocumentValue', () {
    test('constructs and casts typed values correctly', () {
      final textVal = DocumentValue.from('Hello');
      expect(textVal, isA<TextDocumentValue>());
      expect(textVal.asString, 'Hello');
      expect(textVal.isNull, isFalse);

      final intVal = DocumentValue.from(42);
      expect(intVal, isA<IntDocumentValue>());
      expect(intVal.asInt, 42);
      expect(intVal.asDecimal, DecimalNumber.fromInt(42));

      final decVal = DocumentValue.from(DecimalNumber.parse('99.95'));
      expect(decVal, isA<DecimalDocumentValue>());
      expect(decVal.asDecimal, DecimalNumber.parse('99.95'));

      final dateVal = DocumentValue.from(DateTime.utc(2026, 10, 19));
      expect(dateVal, isA<DateTimeDocumentValue>());
      expect(dateVal.asDateTime, DateTime.utc(2026, 10, 19));

      final boolVal = DocumentValue.from(true);
      expect(boolVal, isA<BoolDocumentValue>());
      expect(boolVal.asBool, isTrue);

      final nullVal = DocumentValue.from(null);
      expect(nullVal, isA<NullDocumentValue>());
      expect(nullVal.isNull, isTrue);
      expect(nullVal.asString, isNull);
    });

    test('pattern matching over DocumentValue', () {
      final val = DocumentValue.from(100);
      final result = switch (val) {
        IntDocumentValue(:final value) => 'int:$value',
        DecimalDocumentValue(:final value) => 'dec:$value',
        TextDocumentValue(:final value) => 'text:$value',
        DateDocumentValue(:final value) => 'date:$value',
        DateTimeDocumentValue(:final value) => 'dateTime:$value',
        BoolDocumentValue(:final value) => 'bool:$value',
        NullDocumentValue() => 'null',
      };
      expect(result, 'int:100');
    });
  });

  group('DocumentColumn & DocumentDefinition', () {
    test('creates schema with multiple typed columns', () {
      final schema = DocumentDefinition(
        id: 'test_doc',
        title: 'Test Document',
        columns: [
          DocumentColumn.text(id: 'sku', label: 'SKU', isRequired: true),
          DocumentColumn.decimal(id: 'price', label: 'Price'),
          DocumentColumn.integer(id: 'quantity', label: 'Quantity'),
          DocumentColumn.boolean(id: 'active', label: 'Active'),
        ],
      );

      expect(schema.columns.length, 4);
      expect(schema.hasColumn('sku'), isTrue);
      expect(schema.hasColumn('non_existent'), isFalse);
      expect(schema.getColumn('price')?.type, ColumnType.decimal);
    });

    test('rejects duplicate column ids', () {
      expect(
        () => DocumentDefinition(
          id: 'dup_doc',
          title: 'Duplicate Doc',
          columns: [
            DocumentColumn.text(id: 'col1', label: 'Col 1'),
            DocumentColumn.text(id: 'col1', label: 'Col 1 Duplicate'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('parses and validates raw values according to column type', () {
      final colDec = DocumentColumn.decimal(id: 'amount', label: 'Amount');
      final val1 = colDec.parseValue('123.45');
      expect(val1.asDecimal, DecimalNumber.parse('123.45'));

      final colInt = DocumentColumn.integer(id: 'count', label: 'Count');
      final val2 = colInt.parseValue('55');
      expect(val2.asInt, 55);

      final colBool = DocumentColumn.boolean(id: 'flag', label: 'Flag');
      expect(colBool.parseValue('yes').asBool, isTrue);
      expect(colBool.parseValue('نعم').asBool, isTrue);
      expect(colBool.parseValue('false').asBool, isFalse);
    });
  });

  group('DocumentRow & DocumentDataset', () {
    test('builds immutable dataset and retrieves column values', () {
      final schema = DocumentDefinition(
        id: 'sales',
        title: 'Sales',
        columns: [
          DocumentColumn.text(id: 'item', label: 'Item'),
          DocumentColumn.integer(id: 'qty', label: 'Qty'),
        ],
      );

      final row1 = DocumentRow.fromRaw(
        index: 0,
        rawCells: const {'item': 'Widget A', 'qty': 10},
      );
      final row2 = DocumentRow.fromRaw(
        index: 1,
        rawCells: const {'item': 'Widget B', 'qty': 25},
      );

      final dataset = DocumentDataset(definition: schema, rows: [row1, row2]);
      expect(dataset.length, 2);
      expect(dataset[0]['item'].asString, 'Widget A');
      expect(dataset[1]['qty'].asInt, 25);

      final items = dataset
          .getColumnValues('item')
          .map((v) => v.asString)
          .toList();
      expect(items, ['Widget A', 'Widget B']);
    });
  });

  group('CancellationToken & Progress', () {
    test('triggers cancellation and notifies callbacks', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);

      var notified = false;
      token.onCancelled(() => notified = true);

      token.cancel('User requested stop');
      expect(token.isCancelled, isTrue);
      expect(notified, isTrue);
      expect(token.cancelReason, 'User requested stop');

      expect(
        token.throwIfCancelled,
        throwsA(isA<DocumentCancellationFailure>()),
      );
    });

    test('progress calculates percentage and fraction accurately', () {
      const progress = DocumentProgress(
        phase: DocumentPhase.parsing,
        current: 50,
        total: 200,
        message: 'Parsing rows',
      );

      expect(progress.fraction, 0.25);
      expect(progress.percentage, 25);
      expect(progress.phase, DocumentPhase.parsing);
    });
  });

  group('ExportDefinition formula sanitization', () {
    test('sanitizes formula injection characters', () {
      expect(ExportDefinition.sanitizeFormula('=SUM(A1:A10)'), "'=SUM(A1:A10)");
      expect(ExportDefinition.sanitizeFormula('+12345'), "'+12345");
      expect(ExportDefinition.sanitizeFormula('-987'), "'-987");
      expect(ExportDefinition.sanitizeFormula('@cmd'), "'@cmd");
      expect(ExportDefinition.sanitizeFormula('\tprefix'), "'\tprefix");
      expect(ExportDefinition.sanitizeFormula('Safe Text'), 'Safe Text');
    });
  });
}
