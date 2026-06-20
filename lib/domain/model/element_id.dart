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

  /// Generates a new, practically-unique id (timestamp + randomness, base36).
  factory ElementId.generate() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _rng.nextInt(1 << 32).toRadixString(36);
    return ElementId('el-$ts-$rand');
  }

  @override
  bool operator ==(Object other) => other is ElementId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
