import 'package:calculator2/domain/graph/recompute_engine.dart';
import 'package:calculator2/domain/engine/eval_error.dart';
import 'package:calculator2/domain/model/canvas_doc.dart';
import 'package:calculator2/domain/model/cell_value.dart';
import 'package:calculator2/domain/model/element.dart';
import 'package:calculator2/domain/model/element_id.dart';
import 'package:flutter_test/flutter_test.dart';

EquationElement eq(String id, String raw) =>
    EquationElement(id: ElementId(id), x: 0, y: 0, rawText: raw);

CanvasDoc docWith(List<CanvasElement> els) =>
    CanvasDoc(id: ElementId('canvas'), name: 'c', elements: els);

double valueOf(RecomputeResult r, String id) =>
    (r.valueFor(ElementId(id)) as NumberValue).value;

void main() {
  final engine = RecomputeEngine();

  test('computes independent equations', () {
    final r = engine.compute(docWith([eq('a', '2 + 2'), eq('b', '10 * 3')]));
    expect(valueOf(r, 'a'), 4);
    expect(valueOf(r, 'b'), 30);
  });

  test('linked numbers cascade in dependency order', () {
    // b references a; c references b. Edit propagates down the chain.
    final r = engine.compute(docWith([
      eq('a', '10'),
      eq('b', '@a * 2'),
      eq('c', '@b + 5'),
    ]));
    expect(valueOf(r, 'a'), 10);
    expect(valueOf(r, 'b'), 20);
    expect(valueOf(r, 'c'), 25);
  });

  test('editing a source recomputes all dependents', () {
    final r = engine.compute(docWith([
      eq('a', '7'),
      eq('b', '@a + 1'),
      eq('c', '@b + 1'),
    ]));
    expect(valueOf(r, 'c'), 9);
  });

  test('circular reference is isolated, not fatal', () {
    final r = engine.compute(docWith([
      eq('a', '@b + 1'),
      eq('b', '@a + 1'),
      eq('ok', '3 + 4'),
    ]));
    expect((r.valueFor(ElementId('a')) as ErrorValue).error.kind,
        EvalErrorKind.circularReference);
    expect((r.valueFor(ElementId('b')) as ErrorValue).error.kind,
        EvalErrorKind.circularReference);
    // Unrelated equation still computes.
    expect(valueOf(r, 'ok'), 7);
  });

  test('reference to missing element is an error', () {
    final r = engine.compute(docWith([eq('a', '@missing + 1')]));
    expect(r.valueFor(ElementId('a')), isA<ErrorValue>());
  });

  test('blank equation is empty', () {
    final r = engine.compute(docWith([eq('a', '   ')]));
    expect(r.valueFor(ElementId('a')), isA<EmptyValue>());
  });
}
