import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of components/StatCard.tsx.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});

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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF71717A), letterSpacing: 0.6),
          ),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.foreground)),
        ],
      ),
    );
  }
}
