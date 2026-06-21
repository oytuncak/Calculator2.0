/// Expression AST nodes produced by the [Parser] and consumed by the
/// [Evaluator]. Pure Dart, sealed so the evaluator handles every case.
///
/// The AST is the extension point for the roadmap: named variables and
/// scientific functions add new node types (`VariableRef`, `FunctionCall`)
/// without touching the lexer or the evaluator's existing cases.
sealed class Expr {
  const Expr();
}

class NumberLiteral extends Expr {
  const NumberLiteral(this.value);
  final double value;
}

/// A reference to another element's computed result (`@<id>`).
class Reference extends Expr {
  const Reference(this.elementId);
  final String elementId;
}

/// A bare identifier: a constant (`pi`, `e`) or a named variable (resolved by
/// the [EvalContext]).
class VariableRef extends Expr {
  const VariableRef(this.name);
  final String name;
}

/// A function call such as `sin(x)` or `max(a, b)`.
class FunctionCall extends Expr {
  const FunctionCall(this.name, this.args);
  final String name;
  final List<Expr> args;
}

class Grouping extends Expr {
  const Grouping(this.inner);
  final Expr inner;
}

enum UnaryOperator { negate, percent }

/// Prefix negation (`-x`) or postfix percent (`x%`).
class UnaryOp extends Expr {
  const UnaryOp(this.op, this.operand);
  final UnaryOperator op;
  final Expr operand;
}

enum BinaryOperator { add, subtract, multiply, divide, power }

class BinaryOp extends Expr {
  const BinaryOp(this.op, this.left, this.right);
  final BinaryOperator op;
  final Expr left;
  final Expr right;
}
