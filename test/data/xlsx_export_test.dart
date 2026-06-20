import 'package:calculator2/data/export/xlsx_exporter.dart';
import 'package:calculator2/domain/graph/recompute_engine.dart';
import 'package:calculator2/domain/model/canvas_doc.dart';
import 'package:calculator2/domain/model/element.dart';
import 'package:calculator2/domain/model/element_id.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports canvas results into an .xlsx workbook', () {
    final canvas = CanvasDoc(
      id: ElementId('c'),
      name: 'Budget',
      elements: [
        TextElement(id: ElementId('t'), x: 0, y: 0, text: 'Totals', bold: true),
        EquationElement(id: ElementId('a'), x: 0, y: 60, rawText: '120 * 3'),
        EquationElement(id: ElementId('b'), x: 0, y: 120, rawText: '@a + 50'),
      ],
    );
    final results = RecomputeEngine().compute(canvas);

    final bytes = XlsxExporter().exportBytes(canvas, results);
    expect(bytes, isNotEmpty);

    final decoded = Excel.decodeBytes(bytes);
    // Sheet named after the canvas exists.
    expect(decoded.sheets.keys, contains('Budget'));
    final sheet = decoded['Budget'];

    // Flatten all cell values to strings for simple assertions.
    final values = <String>[];
    for (final row in sheet.rows) {
      for (final cell in row) {
        final v = cell?.value;
        if (v != null) values.add(v.toString());
      }
    }

    expect(values, contains('Totals')); // text note label
    expect(values.any((v) => v.contains('360')), isTrue); // 120*3
    expect(values.any((v) => v.contains('410')), isTrue); // @a + 50
    // The @id reference is rewritten to a readable name, not left raw.
    expect(values.any((v) => v.contains('@')), isFalse);
  });
}
