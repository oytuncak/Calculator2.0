import 'dart:math' as math;

import 'package:calculator2/domain/engine/eval_error.dart';
import 'package:calculator2/domain/engine/evaluator.dart';
import 'package:calculator2/domain/model/cell_value.dart';
import 'package:flutter_test/flutter_test.dart';

double number(String src) {
  final v = evaluateSource(src);
  expect(v, isA<NumberValue>(), reason: 'expected a number for "$src" got $v');
  return (v as NumberValue).value;
}

EvalErrorKind errorKind(String src) =>
    (evaluateSource(src) as ErrorValue).error.kind;

void main() {
  group('functions', () {
    test('trig and roots', () {
      expect(number('sqrt(16)'), 4);
      expect(number('sin(0)'), 0);
      expect(number('cos(0)'), 1);
      expect(closeTo2(number('sin(pi / 2)')), 1);
      expect(number('abs(-7)'), 7);
      expect(number('floor(3.9)'), 3);
      expect(number('ceil(3.1)'), 4);
      expect(number('round(2.5)'), 3);
    });

    test('logs and exp', () {
      expect(closeTo2(number('ln(e)')), 1);
      expect(closeTo2(number('log(1000)')), 3); // base 10
      expect(closeTo2(number('log(2, 8)')), 3); // arbitrary base
      expect(closeTo2(number('exp(0)')), 1);
    });

    test('variadic and multi-arg', () {
      expect(number('max(3, 7, 5)'), 7);
      expect(number('min(3, 7, 5)'), 3);
      expect(number('pow(2, 10)'), 1024);
      expect(number('hypot(3, 4)'), 5);
      expect(number('avg(2, 4, 6)'), 4);
    });

    test('nested and combined with operators', () {
      expect(number('sqrt(9) + max(1, 2) * 2'), 7);
      expect(number('2 ^ sqrt(16)'), 16);
    });
  });

  group('constants', () {
    test('pi, e, tau resolve', () {
      expect(closeTo2(number('pi')), closeTo2(math.pi));
      expect(closeTo2(number('e')), closeTo2(math.e));
      expect(closeTo2(number('tau')), closeTo2(math.pi * 2));
    });
  });

  group('errors', () {
    test('unknown function', () {
      expect(errorKind('frobnicate(2)'), EvalErrorKind.unknownFunction);
    });
    test('unknown variable', () {
      expect(errorKind('x + 1'), EvalErrorKind.unknownVariable);
    });
    test('wrong arity', () {
      expect(errorKind('sin(1, 2)'), EvalErrorKind.arity);
    });
    test('domain error surfaces (sqrt of negative)', () {
      expect(evaluateSource('sqrt(-1)'), isA<ErrorValue>());
    });
  });
}

double closeTo2(double v) => (v * 100).roundToDouble() / 100;
