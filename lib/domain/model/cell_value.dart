import '../engine/eval_error.dart';

/// The computed value of an element: a finite number, empty, or an error.
///
/// Pure Dart. Modelled as a sealed class so callers must handle every case.
sealed class CellValue {
  const CellValue();

  /// Convenience constructor that maps any non-finite double to an error.
  factory CellValue.number(double value) {
    if (value.isNaN || value.isInfinite) {
      return const ErrorValue(EvalError.notANumber());
    }
    return NumberValue(value);
  }

  bool get isError => this is ErrorValue;
  bool get isNumber => this is NumberValue;

  /// The numeric value if this is a [NumberValue], otherwise null.
  double? get asDouble => switch (this) {
        NumberValue(:final value) => value,
        _ => null,
      };
}

class NumberValue extends CellValue {
  const NumberValue(this.value);
  final double value;

  @override
  bool operator ==(Object other) =>
      other is NumberValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'NumberValue($value)';
}

class EmptyValue extends CellValue {
  const EmptyValue();

  @override
  bool operator ==(Object other) => other is EmptyValue;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'EmptyValue()';
}

class ErrorValue extends CellValue {
  const ErrorValue(this.error);
  final EvalError error;

  @override
  bool operator ==(Object other) =>
      other is ErrorValue && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'ErrorValue($error)';
}
