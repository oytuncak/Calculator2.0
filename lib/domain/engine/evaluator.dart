import 'dart:math' as math;

import '../model/cell_value.dart';
import 'eval_context.dart';
import 'eval_error.dart';
import 'expr.dart';
import 'function_registry.dart';
import 'parser.dart';

/// Parses and evaluates [source] in one step, returning any parse or eval
/// failure as an [ErrorValue] instead of throwing.
CellValue evaluateSource(
  String source, [
  EvalContext context = const EmptyEvalContext(),
]) {
  try {
    final expr = Parser.fromSource(source).parse();
    return Evaluator(context).evaluate(expr);
  } on EvalError catch (e) {
    return ErrorValue(e);
  }
}

/// Evaluates an [Expr] tree to a [CellValue].
///
/// Throws are caught internally and surfaced as [ErrorValue] so a single bad
/// cell never breaks the rest of the document.
class Evaluator {
  Evaluator(this.context, {FunctionRegistry? registry})
    : registry = registry ?? FunctionRegistry.standard;

  final EvalContext context;
  final FunctionRegistry registry;

  CellValue evaluate(Expr expr) {
    try {
      return CellValue.number(_eval(expr));
    } on EvalError catch (e) {
      return ErrorValue(e);
    }
  }

  double _eval(Expr expr) {
    switch (expr) {
      case NumberLiteral(:final value):
        return value;
      case Grouping(:final inner):
        return _eval(inner);
      case Reference(:final elementId):
        return _resolve(elementId);
      case VariableRef(:final name):
        return _resolveVariable(name);
      case FunctionCall(:final name, :final args):
        return _call(name, args);
      case UnaryOp(:final op, :final operand):
        final v = _eval(operand);
        return switch (op) {
          UnaryOperator.negate => -v,
          UnaryOperator.percent => v / 100.0,
        };
      case BinaryOp(:final op, :final left, :final right):
        return _binary(op, left, right);
    }
  }

  double _binary(BinaryOperator op, Expr left, Expr right) {
    final l = _eval(left);

    // Contextual percent: when the right operand is a bare `x%`, interpret it
    // relative to the left operand (standard calculator behaviour):
    //   100 + 20%  -> 120     100 - 20%  -> 80
    //   100 * 20%  -> 20      100 / 50%  -> 200
    if (op != BinaryOperator.power &&
        right is UnaryOp &&
        right.op == UnaryOperator.percent) {
      final pct = _eval(right.operand) / 100.0;
      return switch (op) {
        BinaryOperator.add => l + l * pct,
        BinaryOperator.subtract => l - l * pct,
        BinaryOperator.multiply => l * pct,
        BinaryOperator.divide => _guardDivide(l, pct),
        BinaryOperator.power => l, // unreachable (guarded above)
      };
    }

    final r = _eval(right);
    return switch (op) {
      BinaryOperator.add => l + r,
      BinaryOperator.subtract => l - r,
      BinaryOperator.multiply => l * r,
      BinaryOperator.divide => _guardDivide(l, r),
      BinaryOperator.power => math.pow(l, r).toDouble(),
    };
  }

  double _resolveVariable(String name) {
    final constant = kConstants[name.toLowerCase()];
    if (constant != null) return constant;
    final value = context.resolveVariable(name);
    return switch (value) {
      NumberValue(:final value) => value,
      EmptyValue() => throw EvalError.referenceError('"$name" is empty'),
      ErrorValue() => throw EvalError(
        EvalErrorKind.unknownVariable,
        'Unknown name "$name"',
      ),
    };
  }

  double _call(String name, List<Expr> args) {
    final fn = registry.lookup(name);
    if (fn == null) {
      throw EvalError(
        EvalErrorKind.unknownFunction,
        'Unknown function "$name"',
      );
    }
    if (!fn.acceptsArity(args.length)) {
      throw EvalError(
        EvalErrorKind.arity,
        '"$name" got ${args.length} argument(s)',
      );
    }
    return fn.apply(args.map(_eval).toList());
  }

  double _guardDivide(double a, double b) {
    if (b == 0) throw const EvalError.divideByZero();
    return a / b;
  }

  double _resolve(String elementId) {
    final value = context.resolveReference(elementId);
    switch (value) {
      case NumberValue(:final value):
        return value;
      case EmptyValue():
        throw EvalError.referenceError('Reference "@$elementId" is empty');
      case ErrorValue():
        throw EvalError.referenceError('Reference "@$elementId" is in error');
    }
  }
}
