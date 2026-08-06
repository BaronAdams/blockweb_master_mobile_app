import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LinePoint {
  final double y;
  final String label;
  const LinePoint({required this.y, required this.label});
}

/// Port of components/charts/line-chart.tsx's gradient-fill mode, as used
/// by Analytics' 7-day trend (config={{ gradient: true }}) — a smooth-ish
/// polyline with a gradient fill under it and x-axis day labels. Not a
/// full port of every LineChart variant/prop, just the one Analytics uses.
class AppLineChart extends StatelessWidget {
  final List<LinePoint> data;
  final double height;

  const AppLineChart({super.key, required this.data, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    if (data.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, height),
          painter: _LineChartPainter(
            data: data,
            lineColor: colors.primary,
            labelColor: colors.mutedForeground,
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<LinePoint> data;
  final Color lineColor;
  final Color labelColor;

  _LineChartPainter({required this.data, required this.lineColor, required this.labelColor});

  static const double _labelSpace = 18;
  static const double _padding = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - _labelSpace;
    final maxY = data.map((d) => d.y).reduce((a, b) => a > b ? a : b);
    final safeMax = maxY <= 0 ? 1 : maxY;
    final innerWidth = size.width - _padding * 2;
    final stepX = data.length > 1 ? innerWidth / (data.length - 1) : 0.0;

    final points = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(_padding + stepX * i, chartHeight - (data[i].y / safeMax) * chartHeight * 0.9),
    ];

    // Gradient fill under the line.
    final fillPath = Path()..moveTo(points.first.dx, chartHeight);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.35), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Line itself.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Points + x-axis labels.
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3, Paint()..color = lineColor);

      final textPainter = TextPainter(
        text: TextSpan(text: data[i].label, style: TextStyle(fontSize: 10, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, size.height - _labelSpace + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.data != data;
}
