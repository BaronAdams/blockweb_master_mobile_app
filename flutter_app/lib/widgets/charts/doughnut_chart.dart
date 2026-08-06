import 'dart:math' as math;
import 'package:flutter/material.dart';

class DoughnutSegment {
  final Color color;
  final double value;
  const DoughnutSegment({required this.color, required this.value});
}

/// Port of components/charts/doughnut-chart.tsx — a ring (stroked arcs),
/// no labels/legend (the RN screen renders those separately and overlays
/// a percentage in the center), matching how Analytics uses it.
class DoughnutChart extends StatelessWidget {
  final List<DoughnutSegment> data;
  final double size;
  final double strokeWidth;

  const DoughnutChart({super.key, required this.data, this.size = 200, this.strokeWidth = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DoughnutPainter(data: data, strokeWidth: strokeWidth),
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  final List<DoughnutSegment> data;
  final double strokeWidth;
  _DoughnutPainter({required this.data, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold(0.0, (sum, d) => sum + d.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const gapRadians = 0.03;
    var startAngle = -math.pi / 2;
    for (final seg in data) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      final drawSweep = (sweep - gapRadians).clamp(0.0, sweep);
      canvas.drawArc(rect, startAngle + gapRadians / 2, drawSweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter oldDelegate) => oldDelegate.data != data;
}
