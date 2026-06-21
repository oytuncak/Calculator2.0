import 'package:calculator2/domain/graph/recompute_engine.dart';
import 'package:calculator2/domain/model/canvas_doc.dart';
import 'package:calculator2/domain/model/cell_value.dart';
import 'package:calculator2/domain/model/element.dart';
import 'package:calculator2/domain/model/element_id.dart';
import 'package:flutter_test/flutter_test.dart';

EquationElement eq(String id, String raw, {String? name}) =>
    EquationElement(id: ElementId(id), x: 0, y: 0, rawText: raw, label: name);

CanvasDoc docWith(List<CanvasElement> els) =>
    CanvasDoc(id: ElementId('c'), name: 'c', elements: els);

double valueOf(RecomputeResult r, String id) =>
    (r.valueFor(ElementId(id)) as NumberValue).value;

void main() {
  final engine = RecomputeEngine();

  test('reference a named equation by name', () {
    final r = engine.compute(
      docWith([eq('a', '100', name: 'price'), eq('b', 'price * 1.2')]),
    );
    expect(valueOf(r, 'b'), 120);
  });

  test('named-variable edits cascade', () {
    final r = engine.compute(
      docWith([
        eq('a', '10', name: 'qty'),
        eq('b', 'qty * 5', name: 'subtotal'),
        eq('c', 'subtotal + 3'),
      ]),
    );
    expect(valueOf(r, 'b'), 50);
    expect(valueOf(r, 'c'), 53);
  });

  test('a name cycle is isolated as a circular reference', () {
    final r = engine.compute(
      docWith([
        eq('a', 'b + 1', name: 'a'),
        eq('b', 'a + 1', name: 'b'),
        eq('ok', '2 + 2'),
      ]),
    );
    expect(
      (r.valueFor(ElementId('a')) as ErrorValue).error.message,
      contains('Circular'),
    );
    expect(valueOf(r, 'ok'), 4);
  });

  test('unknown name is an error; constants still win', () {
    final r = engine.compute(
      docWith([eq('a', 'unknownThing + 1'), eq('b', 'pi')]),
    );
    expect(r.valueFor(ElementId('a')), isA<ErrorValue>());
    expect(valueOf(r, 'b'), closeTo(3.14159, 0.001));
  });

  test('non-identifier labels are not usable as variables', () {
    expect(isUsableVariableName('sub total'), isFalse);
    expect(isUsableVariableName('2nd'), isFalse);
    expect(isUsableVariableName('pi'), isFalse); // reserved constant
    expect(isUsableVariableName('subtotal'), isTrue);
  });
}
