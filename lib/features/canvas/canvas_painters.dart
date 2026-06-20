import 'package:flutter/material.dart';

import '../../domain/graph/dependency_graph.dart';
import '../../domain/model/element_id.dart';

/// Faint dotted/!lined grid that gives the infinite canvas a "paper" feel.
class GridPainter extends CustomPainter {
  GridPainter({required this.color, this.step = 40});

  final Color color;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter old) =>
      old.color != color || old.step != step;
}

/// Draws connector lines between linked equations (dependent -> dependency)
/// so the cascade is visible at a glance.
class LinkPainter extends CustomPainter {
  LinkPainter({
    required this.bounds,
    required this.graph,
    required this.color,
  });

  /// Canvas-space rectangle for each element.
  final Map<ElementId, Rect> bounds;
  final DependencyGraph graph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = color;

    for (final entry in bounds.entries) {
      final fromRect = entry.value;
      for (final depId in graph.dependenciesOf(entry.key)) {
        final toRect = bounds[depId];
        if (toRect == null) continue;
        final start = fromRect.centerLeft;
        final end = toRect.centerRight;
        // A gentle horizontal-ish cubic so lines read as "flows into".
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx - 40, start.dy,
            end.dx + 40, end.dy,
            end.dx, end.dy,
          );
        canvas.drawPath(path, paint);
        canvas.drawCircle(end, 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(LinkPainter old) =>
      old.bounds != bounds || old.color != color;
}
