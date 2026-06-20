import 'package:excel/excel.dart' hide CellValue;

import '../../domain/graph/recompute_engine.dart';
import '../../domain/engine/number_format.dart';
import '../../domain/model/canvas_doc.dart';
import '../../domain/model/cell_value.dart';
import '../../domain/model/element.dart';
import '../../domain/model/element_id.dart';

/// Exports a canvas to an `.xlsx` workbook.
///
/// Layout (deterministic and spreadsheet-friendly): a title row, then one row
/// per element — text notes become bold label cells; equations put their
/// (human-readable) expression in column A and the computed result in column B.
/// `@id` references are rewritten to readable names. Pure Dart, so the byte
/// output is unit-testable without a device.
class XlsxExporter {
  /// Builds the workbook and returns its encoded bytes.
  List<int> exportBytes(CanvasDoc canvas, RecomputeResult results) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    final sheetName = _safeSheetName(canvas.name);
    final sheet = excel[sheetName];

    // Friendly names for equations, used both as labels and to de-reference
    // `@id` tokens in exported expressions.
    final names = _equationNames(canvas);

    var row = 0;
    _setText(sheet, 0, row, 'Calculator 2.0 — ${canvas.name}', bold: true);
    row += 2;
    _setText(sheet, 0, row, 'Item', bold: true);
    _setText(sheet, 1, row, 'Result', bold: true);
    row++;

    for (final element in canvas.elements) {
      switch (element) {
        case TextElement():
          if (element.text.trim().isEmpty) continue;
          _setText(sheet, 0, row, element.text, bold: element.bold);
          row++;
        case EquationElement():
          final label = names[element.id]!;
          final expr = _readableExpression(element.rawText, names);
          _setText(sheet, 0, row, '$label:  $expr');
          _setResult(sheet, 1, row, results.valueFor(element.id));
          row++;
      }
    }

    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.delete(defaultSheet);
    }
    return excel.encode() ?? const [];
  }

  Map<ElementId, String> _equationNames(CanvasDoc canvas) {
    final map = <ElementId, String>{};
    var i = 1;
    for (final e in canvas.elements) {
      if (e is EquationElement) {
        map[e.id] = (e.label != null && e.label!.trim().isNotEmpty)
            ? e.label!.trim()
            : 'E$i';
        i++;
      }
    }
    return map;
  }

  String _readableExpression(String rawText, Map<ElementId, String> names) {
    var out = rawText;
    names.forEach((id, name) {
      out = out.replaceAll('@${id.value}', name);
    });
    return out;
  }

  void _setText(
    Sheet sheet,
    int col,
    int row,
    String value, {
    bool bold = false,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = TextCellValue(value);
    if (bold) cell.cellStyle = CellStyle(bold: true);
  }

  void _setResult(Sheet sheet, int col, int row, CellValue value) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    switch (value) {
      case NumberValue(:final value):
        cell.value = DoubleCellValue(value);
      case ErrorValue():
        cell.value = TextCellValue(formatCellValue(value));
      case EmptyValue():
        cell.value = TextCellValue('');
    }
  }

  String _safeSheetName(String name) {
    // Excel sheet names: max 31 chars, no : \ / ? * [ ]
    final cleaned = name.replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ').trim();
    final result = cleaned.isEmpty ? 'Canvas' : cleaned;
    return result.length > 31 ? result.substring(0, 31) : result;
  }
}
