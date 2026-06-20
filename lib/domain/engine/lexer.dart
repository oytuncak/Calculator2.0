import 'eval_error.dart';
import 'token.dart';

/// Converts a raw expression string into a list of [Token]s.
///
/// Supports numbers (with decimals and thousands separators stripped),
/// the operators `+ - * / %`, parentheses, and `@<id>` reference tokens.
/// Throws [EvalError] (syntax) on an unexpected character.
///
/// A reference id is everything after `@` up to the next character that is
/// not a letter, digit, `-` or `_` (uuids contain hyphens).
class Lexer {
  Lexer(this._source);

  final String _source;
  int _pos = 0;

  List<Token> tokenize() {
    final tokens = <Token>[];
    while (!_isAtEnd) {
      final c = _peek();
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        _pos++;
        continue;
      }
      final start = _pos;
      switch (c) {
        case '+':
          tokens.add(_single(TokenType.plus, '+', start));
        case '-':
          tokens.add(_single(TokenType.minus, '-', start));
        // Accept common typographic variants for multiply/divide.
        case '*':
        case '×': // ×
          tokens.add(_single(TokenType.star, '*', start));
        case '/':
        case '÷': // ÷
          tokens.add(_single(TokenType.slash, '/', start));
        case '%':
          tokens.add(_single(TokenType.percent, '%', start));
        case '(':
          tokens.add(_single(TokenType.lparen, '(', start));
        case ')':
          tokens.add(_single(TokenType.rparen, ')', start));
        case '@':
          tokens.add(_reference(start));
        default:
          if (_isDigit(c) || c == '.') {
            tokens.add(_number(start));
          } else {
            throw EvalError.syntax('Unexpected character "$c"');
          }
      }
    }
    tokens.add(Token(TokenType.eof, '', _pos));
    return tokens;
  }

  Token _single(TokenType type, String lexeme, int start) {
    _pos++;
    return Token(type, lexeme, start);
  }

  Token _reference(int start) {
    _pos++; // consume '@'
    final buf = StringBuffer();
    while (!_isAtEnd) {
      final c = _peek();
      if (_isLetter(c) || _isDigit(c) || c == '-' || c == '_') {
        buf.write(c);
        _pos++;
      } else {
        break;
      }
    }
    final id = buf.toString();
    if (id.isEmpty) {
      throw const EvalError.syntax('Empty reference after "@"');
    }
    return Token(TokenType.reference, '@$id', start, refId: id);
  }

  Token _number(int start) {
    final buf = StringBuffer();
    var seenDot = false;
    while (!_isAtEnd) {
      final c = _peek();
      if (_isDigit(c)) {
        buf.write(c);
        _pos++;
      } else if (c == '.') {
        if (seenDot) break;
        seenDot = true;
        buf.write(c);
        _pos++;
      } else if (c == ',') {
        // Thousands separator: ignore so "1,000" parses as 1000.
        _pos++;
      } else {
        break;
      }
    }
    final lexeme = buf.toString();
    final value = double.tryParse(lexeme);
    if (value == null) {
      throw EvalError.syntax('Invalid number "$lexeme"');
    }
    return Token(TokenType.number, lexeme, start, number: value);
  }

  bool get _isAtEnd => _pos >= _source.length;
  String _peek() => _source[_pos];

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  static bool _isLetter(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
  }
}
