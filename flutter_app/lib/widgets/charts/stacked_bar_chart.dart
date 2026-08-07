import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StackedSegment {
  final String key;
  final double value;
  final Color color;
  const StackedSegment({required this.key, required this.value, required this.color});
}

class StackedBarDataPoint {
  final String label;
  final List<StackedSegment> segments;
  const StackedBarDataPoint({required this.label, required this.segments});
}

/// Port of components/charts/stacked-bar-chart.tsx — CustomPainter instead
/// of react-native-svg, tap-to-select instead of per-shape onPress: each
/// of the 24 bars always renders a full-height translucent "track", plus
/// stacked category-colored fill segments growing from the bottom
/// proportional to value/maxTotal. selectedIndex dims non-selected bars.
class StackedBarChart extends StatelessWidget {
  final List<StackedBarDataPoint> data;
  final double height;
  final int labelEvery;
  final int? selectedIndex;
  final ValueChanged<int>? onBarTap;

  const StackedBarChart({
    super.key,
    required this.data,
    this.height = 160,
    this.labelEvery = 1,
    this.selectedIndex,
    this.onBarTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    if (data.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onTapUp: onBarTap == null
              ? null
              : (details) {
                  // num.clamp() always returns num, even called on an int —
                  // .toInt() is load-bearing, onBarTap needs a real int.
                  final index = (details.localPosition.dx / width * data.length).floor().clamp(0, data.length - 1).toInt();
                  onBarTap!(index);
                },
          child: CustomPaint(
            size: Size(width, height),
            painter: _StackedBarPainter(
              data: data,
              labelEvery: labelEvery,
              selectedIndex: selectedIndex,
              trackColor: colors.mutedForeground,
              labelColor: colors.mutedForeground,
            ),
          ),
        );
      },
    );
  }
}

class _StackedBarPainter extends CustomPainter {
  final List<StackedBarDataPoint> data;
  final int labelEvery;
  final int? selectedIndex;
  final Color trackColor;
  final Color labelColor;

  _StackedBarPainter({
    required this.data,
    required this.labelEvery,
    required this.selectedIndex,
    required this.trackColor,
    required this.labelColor,
  });

  static const double _padding = 4;
  static const double _labelSpace = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final totals = data.map((d) => d.segments.fold(0.0, (sum, s) => sum + s.value)).toList();
    final maxTotal = totals.isEmpty ? 0.0 : totals.reduce((a, b) => a > b ? a : b);

    final innerWidth = size.width - _padding * 2;
    final chartHeight = size.height - _labelSpace;
    final barWidth = (innerWidth / data.length) * 0.7;
    final barSpacing = (innerWidth / data.length) * 0.3;
    const trackTop = 0.0;
    final trackBottom = chartHeight;

    for (var index = 0; index < data.length; index++) {
      final item = data[index];
      final total = totals[index];
      final x = _padding + index * (barWidth + barSpacing) + barSpacing / 2;
      final isDimmed = selectedIndex != null && selectedIndex != index;
      final trackOpacity = isDimmed ? 0.06 : 0.12;
      final fillOpacity = isDimmed ? 0.35 : 1.0;

      final trackPaint = Paint()..color = trackColor.withOpacity(trackOpacity);
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, trackTop, barWidth, chartHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(trackRect, trackPaint);

      if (maxTotal > 0 && total > 0) {
        var cumulativeY = trackBottom;
        for (final seg in item.segments) {
          if (seg.value <= 0) continue;
          final segHeight = (seg.value / maxTotal) * chartHeight;
          final segPaint = Paint()..color = seg.color.withOpacity(fillOpacity);
          canvas.drawRect(Rect.fromLTWH(x, cumulativeY - segHeight, barWidth, segHeight), segPaint);
          cumulativeY -= segHeight;
        }
      }

      if (index % labelEvery == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: item.label,
            style: TextStyle(fontSize: 9, color: labelColor.withOpacity(isDimmed ? 0.5 : 1)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(x + barWidth / 2 - textPainter.width / 2, size.height - _labelSpace + 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StackedBarPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.selectedIndex != selectedIndex;
}
