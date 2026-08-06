import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of components/charts/chart-container.tsx.
class ChartContainer extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget child;

  const ChartContainer({super.key, this.title, this.description, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(title!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.foreground)),
            ),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(description!, style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
            ),
          child,
        ],
      ),
    );
  }
}

/// Port of the RN file's local EmptyChartState.
class EmptyChartState extends StatelessWidget {
  final String label;
  final String hint;
  const EmptyChartState({super.key, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, height: 1.3, color: colors.mutedForeground.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
