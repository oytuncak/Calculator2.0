import 'dart:math';

/// Opaque, stable identifier for a canvas element.
///
/// References between equations use this id (not screen position), so they
/// survive moves, renames and serialization. Pure Dart — generates ids without
/// any package dependency so the domain stays testable with `dart test`.
class ElementId {
  const ElementId(this.value);

  final String value;

  static final Random _rng = Random();

  // Web-safe random bound: `1 << 32` evaluates to 0 in JavaScript (bitwise ops
  // are 32-bit), and Random.nextInt(0) throws. 2^30 is positive on every target.
  static const int _randBound = 1 << 30;

  /// Generates a new, practically-unique id (timestamp + randomness, base36).
  factory ElementId.generate() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final a = _rng.nextInt(_randBound).toRadixString(36);
    final b = _rng.nextInt(_randBound).toRadixString(36);
    return ElementId('el-$ts-$a$b');
  }

  @override
  bool operator ==(Object other) => other is ElementId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
