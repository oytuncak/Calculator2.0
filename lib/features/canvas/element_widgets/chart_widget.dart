import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/ai_commands.dart';
import '../../../domain/model/element.dart';
import '../../../domain/model/element_id.dart';
import '../../../state/document_controller.dart';
import 'equation_widget.dart' show ElementRef;

/// A chart that plots the live results of the equations it references. Drop an
/// equation's result pill onto it to add a series; switch between bar/line/pie.
class ChartWidget extends ConsumerWidget {
  const ChartWidget({
    super.key,
    required this.element,
    required this.state,
    required this.selected,
    required this.scaleGetter,
  });

  final ChartElement element;
  final DocumentState state;
  final bool selected;
  final double Function() scaleGetter;

  static const _palette = [
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFFA855F7),
  ];

  DocumentController _controller(WidgetRef ref) =>
      ref.read(documentControllerProvider.notifier);

  /// Display name for each equation on the canvas (label, else E1/E2/…).
  Map<ElementId, String> _names() {
    final map = <ElementId, String>{};
    var i = 1;
    for (final e in state.canvas.elements) {
      if (e is EquationElement) {
        map[e.id] = (e.label != null && e.label!.trim().isNotEmpty)
            ? e.label!.trim()
            : 'E$i';
        i++;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final names = _names();
    final series = <_Series>[];
    for (final id in element.sources) {
      final v = state.valueFor(id).asDouble;
      if (v != null) series.add(_Series(names[id] ?? '?', v, id));
    }

    return DragTarget<ElementRef>(
      onWillAcceptWithDetails: (d) => !element.sources.contains(d.data.id),
      onAcceptWithDetails: (d) => _controller(
        ref,
      ).apply(AddChartSource(chart: element.id, source: d.data.id)),
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        return SizedBox(
          width: element.width,
          height: element.height,
          child: GestureDetector(
            onTap: () => _controller(ref).select(element.id),
            child: Card(
              color: highlight ? scheme.primaryContainer : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context, ref, scheme),
                    Expanded(
                      child: series.isEmpty
                          ? _empty(scheme)
                          : _chart(scheme, series),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, ColorScheme scheme) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) {
            final s = scaleGetter();
            _controller(ref).apply(
              MoveElement(
                element.id,
                element.x + d.delta.dx / s,
                element.y + d.delta.dy / s,
              ),
            );
          },
          child: Icon(
            Icons.drag_indicator,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            element.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _typeButton(ref, ChartType.bar, Icons.bar_chart, scheme),
        _typeButton(ref, ChartType.line, Icons.show_chart, scheme),
        _typeButton(ref, ChartType.pie, Icons.pie_chart_outline, scheme),
        InkWell(
          onTap: () => _controller(ref).apply(DeleteElement(element.id)),
          child: Icon(Icons.close, size: 16, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _typeButton(
    WidgetRef ref,
    ChartType type,
    IconData icon,
    ColorScheme scheme,
  ) {
    final active = element.chartType == type;
    return InkWell(
      onTap: () => _controller(ref).apply(SetChartType(element.id, type)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Icon(
          icon,
          size: 18,
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _empty(ColorScheme scheme) => Center(
    child: Text(
      'Drag a result here\nto chart it',
      textAlign: TextAlign.center,
      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
    ),
  );

  Widget _chart(ColorScheme scheme, List<_Series> series) {
    return switch (element.chartType) {
      ChartType.bar => _bar(scheme, series),
      ChartType.line => _line(scheme, series),
      ChartType.pie => _pie(scheme, series),
    };
  }

  Color _color(int i) => _palette[i % _palette.length];

  FlTitlesData _bottomNameTitles(List<_Series> series, ColorScheme scheme) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 30),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final i = value.round();
            if (i < 0 || i >= series.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                series[i].name,
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bar(ColorScheme scheme, List<_Series> series) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: _bottomNameTitles(series, scheme),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < series.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: series[i].value,
                  color: _color(i),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _line(ColorScheme scheme, List<_Series> series) {
    return LineChart(
      LineChartData(
        titlesData: _bottomNameTitles(series, scheme),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < series.length; i++)
                FlSpot(i.toDouble(), series[i].value),
            ],
            isCurved: false,
            color: scheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _pie(ColorScheme scheme, List<_Series> series) {
    final total = series.fold<double>(0, (s, e) => s + e.value.abs());
    if (total == 0) {
      return Center(
        child: Text(
          'No data to chart',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
      );
    }
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        sections: [
          for (var i = 0; i < series.length; i++)
            PieChartSectionData(
              value: series[i].value.abs(),
              color: _color(i),
              title: series[i].name,
              radius: 52,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _Series {
  const _Series(this.name, this.value, this.id);
  final String name;
  final double value;
  final ElementId id;
}
