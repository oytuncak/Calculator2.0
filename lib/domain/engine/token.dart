/// Token types produced by the [Lexer].
enum TokenType {
  number,
  plus,
  minus,
  star,
  slash,
  percent,
  lparen,
  rparen,

  /// A reference to another element's result, written as `@<elementId>`.
  reference,

  eof,
}

class Token {
  const Token(this.type, this.lexeme, this.start, {this.number, this.refId});

  final TokenType type;
  final String lexeme;

  /// Offset of the first character of this token in the source string.
  final int start;

  /// Parsed numeric value, only set for [TokenType.number].
  final double? number;

  /// Referenced element id, only set for [TokenType.reference].
  final String? refId;

  @override
  String toString() => 'Token(${type.name}, "$lexeme")';
}
