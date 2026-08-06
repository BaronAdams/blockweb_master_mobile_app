import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of components/SectionTitle.tsx.
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;

  const SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: color ?? colors.mutedForeground,
        ),
      ),
    );
  }
}
