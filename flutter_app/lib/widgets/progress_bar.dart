import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _red = Color(0xFFF43F5E);

/// Port of components/ui/progress.tsx.
class AppProgressBar extends StatelessWidget {
  final double value; // 0..100
  final double height;
  const AppProgressBar({super.key, required this.value, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    // num.clamp() always returns num, even on a double receiver — the
    // .toDouble() is load-bearing, not decorative (LinearProgressIndicator
    // .value is strictly double?).
    final clamped = value.clamp(0, 100).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: clamped / 100,
        minHeight: height,
        backgroundColor: colors.border,
        // Full/over the limit reads as a warning, not just "100% done".
        valueColor: AlwaysStoppedAnimation<Color>(clamped >= 100 ? _red : colors.primary),
      ),
    );
  }
}
