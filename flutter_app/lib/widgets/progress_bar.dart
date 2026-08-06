import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of components/ui/progress.tsx.
class AppProgressBar extends StatelessWidget {
  final double value; // 0..100
  final double height;
  const AppProgressBar({super.key, required this.value, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: (value.clamp(0, 100)) / 100,
        minHeight: height,
        backgroundColor: colors.border,
        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
      ),
    );
  }
}
