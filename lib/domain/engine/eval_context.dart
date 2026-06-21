import '../model/cell_value.dart';
import 'eval_error.dart';
import 'expr.dart';

/// Resolver seam used by the [Evaluator].
///
/// The evaluator never knows about the document or dependency graph — it asks
/// the context to resolve a reference. The same interface will later resolve
/// named variables and scientific functions, and can be backed by an
/// AI/natural-language front-end.
abstract interface class EvalContext {
  /// Returns the current computed value of the referenced element, or an
  /// [ErrorValue] / [EmptyValue] if it is unavailable.
  CellValue resolveReference(String elementId);
}

/// A context with no references available — useful for evaluating standalone
/// expressions and in tests.
class EmptyEvalContext implements EvalContext {
  const EmptyEvalContext();

  @override
  CellValue resolveReference(String elementId) =>
      const ErrorValue(EvalError.unknownReference('No references available'));
}

/// Walks an [Expr] tree and collects every referenced element id. Used by the
/// dependency graph to build edges without evaluating.
Set<String> collectReferences(Expr expr) {
  final ids = <String>{};
  void visit(Expr e) {
    switch (e) {
      case NumberLiteral():
      case VariableRef():
        break;
      case Reference(:final elementId):
        ids.add(elementId);
      case Grouping(:final inner):
        visit(inner);
      case UnaryOp(:final operand):
        visit(operand);
      case BinaryOp(:final left, :final right):
        visit(left);
        visit(right);
      case FunctionCall(:final args):
        for (final a in args) {
          visit(a);
        }
    }
  }

  visit(expr);
  return ids;
}
