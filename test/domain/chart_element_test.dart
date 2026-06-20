import 'package:calculator2/domain/model/element.dart';
import 'package:calculator2/domain/model/element_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChartElement round-trips through JSON via the element dispatcher', () {
    final chart = ChartElement(
      id: ElementId('ch'),
      x: 12,
      y: 34,
      title: 'Spend',
      chartType: ChartType.pie,
      sources: [ElementId('a'), ElementId('b')],
    );

    final restored = CanvasElement.fromJson(chart.toJson());
    expect(restored, isA<ChartElement>());
    final r = restored as ChartElement;
    expect(r.title, 'Spend');
    expect(r.chartType, ChartType.pie);
    expect(r.sources, [ElementId('a'), ElementId('b')]);
    expect(r.x, 12);
  });

  test('ChartType.fromName falls back to bar for unknown values', () {
    expect(ChartType.fromName('line'), ChartType.line);
    expect(ChartType.fromName('nonsense'), ChartType.bar);
    expect(ChartType.fromName(null), ChartType.bar);
  });
}
