import 'package:calculator2/domain/model/element_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate() produces non-empty, unique ids', () {
    final ids = <String>{};
    for (var i = 0; i < 5000; i++) {
      final id = ElementId.generate();
      expect(id.value, isNotEmpty);
      ids.add(id.value);
    }
    // No collisions across many rapid generations.
    expect(ids.length, 5000);
  });

  test('equality is by value', () {
    expect(const ElementId('x'), const ElementId('x'));
    expect(const ElementId('x'), isNot(const ElementId('y')));
  });
}
