import '../model/cell_value.dart';

/// Formats a [CellValue] for display on the canvas.
///
/// Trims insignificant trailing zeros, caps at a sensible number of decimals,
/// and shows a short symbol for empty / error cells.
String formatCellValue(CellValue value, {int maxDecimals = 8}) {
  switch (value) {
    case EmptyValue():
      return '';
    case ErrorValue(:final error):
      return 'Error: ${error.message}';
    case NumberValue(:final value):
      return formatNumber(value, maxDecimals: maxDecimals);
  }
}

String formatNumber(double n, {int maxDecimals = 8}) {
  if (n == 0) return '0';
  if (!n.isFinite) return 'Error';

  final abs = n.abs();
  // Use scientific notation for very large / very small magnitudes.
  if (abs >= 1e15 || abs < 1e-9) {
    return n.toStringAsExponential(4).replaceAll(RegExp(r'\.?0+e'), 'e');
  }

  var s = n.toStringAsFixed(maxDecimals);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}
