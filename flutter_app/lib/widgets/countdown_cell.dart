import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of components/CountdownCell.tsx.
class CountdownCell extends StatelessWidget {
  final int value;
  final String label;
  const CountdownCell({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: colors.foreground),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF71717A)),
            ),
          ],
        ),
      ),
    );
  }
}
