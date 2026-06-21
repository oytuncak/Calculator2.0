import 'dart:math' as math;

import 'eval_error.dart';

/// A built-in function: its allowed argument count and its implementation.
class FunctionDef {
  const FunctionDef(this.name, this.minArgs, this.maxArgs, this.apply);

  final String name;
  final int minArgs;

  /// Maximum argument count, or `-1` for variadic (e.g. `min`, `max`).
  final int maxArgs;
  final double Function(List<double> args) apply;

  bool acceptsArity(int n) => n >= minArgs && (maxArgs < 0 || n <= maxArgs);
}

/// Registry of scientific functions. New functions are added here without
/// touching the lexer/parser/evaluator — the architecture's extension point.
class FunctionRegistry {
  FunctionRegistry._();

  /// Shared default registry with the standard scientific functions.
  static final FunctionRegistry standard = FunctionRegistry._()
    .._registerStandard();

  final Map<String, FunctionDef> _fns = {};

  FunctionDef? lookup(String name) => _fns[name.toLowerCase()];

  void register(FunctionDef def) => _fns[def.name.toLowerCase()] = def;

  void _registerStandard() {
    void one(String name, double Function(double) f) =>
        register(FunctionDef(name, 1, 1, (a) => f(a[0])));

    one('sin', math.sin);
    one('cos', math.cos);
    one('tan', math.tan);
    one('asin', math.asin);
    one('acos', math.acos);
    one('atan', math.atan);
    one('sinh', (x) => (math.exp(x) - math.exp(-x)) / 2);
    one('cosh', (x) => (math.exp(x) + math.exp(-x)) / 2);
    one('tanh', (x) {
      final a = math.exp(x), b = math.exp(-x);
      return (a - b) / (a + b);
    });
    one('exp', math.exp);
    one('abs', (x) => x.abs());
    one('sign', (x) => x.sign);
    one('round', (x) => x.roundToDouble());
    one('floor', (x) => x.floorToDouble());
    one('ceil', (x) => x.ceilToDouble());
    one('rad', (x) => x * math.pi / 180);
    one('deg', (x) => x * 180 / math.pi);

    one('sqrt', (x) {
      if (x < 0) {
        throw const EvalError(EvalErrorKind.notANumber, 'sqrt of negative');
      }
      return math.sqrt(x);
    });
    one(
      'cbrt',
      (x) => x.isNegative
          ? -math.pow(-x, 1 / 3).toDouble()
          : math.pow(x, 1 / 3).toDouble(),
    );
    one('ln', (x) {
      if (x <= 0) {
        throw const EvalError(EvalErrorKind.notANumber, 'ln of non-positive');
      }
      return math.log(x);
    });
    one('log10', (x) {
      if (x <= 0) {
        throw const EvalError(EvalErrorKind.notANumber, 'log of non-positive');
      }
      return math.log(x) / math.ln10;
    });

    // log(x) = base-10; log(base, x) = arbitrary base.
    register(
      FunctionDef('log', 1, 2, (a) {
        if (a.length == 1) {
          if (a[0] <= 0) {
            throw const EvalError(
              EvalErrorKind.notANumber,
              'log of non-positive',
            );
          }
          return math.log(a[0]) / math.ln10;
        }
        final base = a[0], x = a[1];
        if (base <= 0 || base == 1 || x <= 0) {
          throw const EvalError(EvalErrorKind.notANumber, 'invalid log');
        }
        return math.log(x) / math.log(base);
      }),
    );

    register(FunctionDef('pow', 2, 2, (a) => math.pow(a[0], a[1]).toDouble()));
    register(
      FunctionDef('root', 2, 2, (a) => math.pow(a[1], 1 / a[0]).toDouble()),
    );
    register(FunctionDef('mod', 2, 2, (a) => a[0] % a[1]));
    register(
      FunctionDef('hypot', 2, 2, (a) => math.sqrt(a[0] * a[0] + a[1] * a[1])),
    );

    register(FunctionDef('min', 1, -1, (a) => a.reduce(math.min)));
    register(FunctionDef('max', 1, -1, (a) => a.reduce(math.max)));
    register(
      FunctionDef('avg', 1, -1, (a) => a.reduce((x, y) => x + y) / a.length),
    );
    register(FunctionDef('sum', 1, -1, (a) => a.reduce((x, y) => x + y)));
  }
}

/// Mathematical constants resolved for bare identifiers like `pi` and `e`.
const Map<String, double> kConstants = {
  'pi': math.pi,
  'e': math.e,
  'tau': math.pi * 2,
};
