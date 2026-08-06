import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of components/onboarding/ChoiceCard.tsx.
class ChoiceCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const ChoiceCard({super.key, required this.label, required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withOpacity(0.08) : colors.card,
          border: Border.all(color: selected ? colors.primary : colors.border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.foreground))),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(Icons.check_rounded, size: 13, color: colors.primaryForeground),
              ),
          ],
        ),
      ),
    );
  }
}
