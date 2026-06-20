import 'eval_error.dart';
import 'expr.dart';
import 'lexer.dart';
import 'token.dart';

/// Recursive-descent / precedence-climbing (Pratt) parser.
///
/// Grammar (lowest to highest precedence):
///   expression := term (('+' | '-') term)*
///   term       := factor (('*' | '/') factor)*
///   factor     := unary
///   unary      := '-' unary | postfix
///   postfix    := primary '%'*
///   primary    := NUMBER | REFERENCE | '(' expression ')'
///
/// Adding a precedence level (e.g. '^' for exponent) or a new primary
/// (function calls, variables) is a localized change here.
class Parser {
  Parser(this._tokens);

  factory Parser.fromSource(String source) => Parser(Lexer(source).tokenize());

  final List<Token> _tokens;
  int _pos = 0;

  /// Parses a complete expression. Throws [EvalError] (syntax) on failure.
  Expr parse() {
    if (_peek().type == TokenType.eof) {
      throw const EvalError.syntax('Empty expression');
    }
    final expr = _expression();
    if (_peek().type != TokenType.eof) {
      throw EvalError.syntax('Unexpected "${_peek().lexeme}"');
    }
    return expr;
  }

  Expr _expression() {
    var left = _term();
    while (_match(TokenType.plus) || _match(TokenType.minus)) {
      final op = _previous().type == TokenType.plus
          ? BinaryOperator.add
          : BinaryOperator.subtract;
      final right = _term();
      left = BinaryOp(op, left, right);
    }
    return left;
  }

  Expr _term() {
    var left = _unary();
    while (_match(TokenType.star) || _match(TokenType.slash)) {
      final op = _previous().type == TokenType.star
          ? BinaryOperator.multiply
          : BinaryOperator.divide;
      final right = _unary();
      left = BinaryOp(op, left, right);
    }
    return left;
  }

  Expr _unary() {
    if (_match(TokenType.minus)) {
      return UnaryOp(UnaryOperator.negate, _unary());
    }
    return _postfix();
  }

  Expr _postfix() {
    var expr = _primary();
    while (_match(TokenType.percent)) {
      expr = UnaryOp(UnaryOperator.percent, expr);
    }
    return expr;
  }

  Expr _primary() {
    final token = _peek();
    switch (token.type) {
      case TokenType.number:
        _advance();
        return NumberLiteral(token.number!);
      case TokenType.reference:
        _advance();
        return Reference(token.refId!);
      case TokenType.lparen:
        _advance();
        final inner = _expression();
        _expect(TokenType.rparen, 'Expected ")"');
        return Grouping(inner);
      default:
        throw EvalError.syntax(
          token.type == TokenType.eof
              ? 'Unexpected end of expression'
              : 'Unexpected "${token.lexeme}"',
        );
    }
  }

  // --- token helpers ---

  Token _peek() => _tokens[_pos];
  Token _previous() => _tokens[_pos - 1];
  Token _advance() => _tokens[_pos++];

  bool _match(TokenType type) {
    if (_peek().type == type) {
      _advance();
      return true;
    }
    return false;
  }

  void _expect(TokenType type, String message) {
    if (!_match(type)) throw EvalError.syntax(message);
  }
}
