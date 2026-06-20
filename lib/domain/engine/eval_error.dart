/// Errors produced while evaluating an expression.
///
/// Pure Dart — no Flutter imports. These are surfaced to the user as the
/// result of a [CellValue] so the rest of the document keeps computing even
/// when one cell is broken.
library;

enum EvalErrorKind {
  /// The expression could not be tokenized or parsed.
  syntax,

  /// Division (or modulo) by zero.
  divideByZero,

  /// A reference (`@id`) points at an element that does not exist.
  unknownReference,

  /// A reference points at an element that is itself in error / empty.
  referenceError,

  /// Adding this reference would create a cycle in the dependency graph.
  circularReference,

  /// A numeric result that is not finite (e.g. overflow, 0/0).
  notANumber,
}

class EvalError implements Exception {
  const EvalError(this.kind, this.message);

  final EvalErrorKind kind;
  final String message;

  const EvalError.syntax(String message)
      : this(EvalErrorKind.syntax, message);
  const EvalError.divideByZero()
      : this(EvalErrorKind.divideByZero, 'Division by zero');
  const EvalError.unknownReference(String message)
      : this(EvalErrorKind.unknownReference, message);
  const EvalError.referenceError(String message)
      : this(EvalErrorKind.referenceError, message);
  const EvalError.circularReference()
      : this(EvalErrorKind.circularReference, 'Circular reference');
  const EvalError.notANumber()
      : this(EvalErrorKind.notANumber, 'Not a number');

  @override
  String toString() => 'EvalError(${kind.name}: $message)';

  @override
  bool operator ==(Object other) =>
      other is EvalError && other.kind == kind && other.message == message;

  @override
  int get hashCode => Object.hash(kind, message);
}
