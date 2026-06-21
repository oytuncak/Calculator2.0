import 'package:calculator2/domain/engine/eval_error.dart';
import 'package:calculator2/domain/engine/evaluator.dart';
import 'package:calculator2/domain/engine/number_format.dart';
import 'package:calculator2/domain/model/cell_value.dart';
import 'package:flutter_test/flutter_test.dart';

CellValue eval(String src) => evaluateSource(src);

double number(String src) {
  final v = eval(src);
  expect(
    v,
    isA<NumberValue>(),
    reason: 'expected a number for "$src" but got $v',
  );
  return (v as NumberValue).value;
}

void main() {
  group('arithmetic', () {
    test('basic operators and precedence', () {
      expect(number('1 + 2'), 3);
      expect(number('2 + 3 * 4'), 14);
      expect(number('(2 + 3) * 4'), 20);
      expect(number('10 - 4 - 3'), 3); // left associative
      expect(number('20 / 4 / 5'), 1);
      expect(number('-5 + 2'), -3);
      expect(number('2 * -3'), -6);
    });

    test('decimals', () {
      expect(number('1.5 + 2.5'), 4);
      expect(number('.5 * 2'), 1);
    });

    test('exponent operator (right-associative)', () {
      expect(number('2 ^ 3'), 8);
      expect(number('2 ^ 3 ^ 2'), 512); // 2^(3^2)
      expect(number('-2 ^ 2'), -4); // -(2^2)
      expect(number('2 ^ -1'), 0.5);
    });

    test('typographic operators', () {
      expect(number('6 × 7'), 42);
      expect(number('84 ÷ 2'), 42);
    });
  });

  group('percent', () {
    test('standalone percent divides by 100', () {
      expect(number('50%'), 0.5);
    });

    test('contextual percent', () {
      expect(number('100 + 20%'), 120);
      expect(number('100 - 20%'), 80);
      expect(number('100 * 20%'), 20);
      expect(number('100 / 50%'), 200);
    });
  });

  group('errors', () {
    test('division by zero', () {
      final v = eval('1 / 0');
      expect(v, isA<ErrorValue>());
      expect((v as ErrorValue).error.kind, EvalErrorKind.divideByZero);
    });

    test('syntax error', () {
      final v = eval('1 +');
      expect(v, isA<ErrorValue>());
      expect((v as ErrorValue).error.kind, EvalErrorKind.syntax);
    });

    test('unexpected character', () {
      expect(eval('1 # 2'), isA<ErrorValue>());
    });
  });

  group('number formatting', () {
    test('trims trailing zeros', () {
      expect(formatNumber(4.0), '4');
      expect(formatNumber(1.5), '1.5');
      expect(formatNumber(0.0), '0');
    });

    test('rounds long decimals', () {
      expect(formatNumber(1 / 3), '0.33333333');
    });
  });
}
