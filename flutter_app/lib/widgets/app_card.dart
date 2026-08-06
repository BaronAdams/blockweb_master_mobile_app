import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Port of components/ui/card.tsx + components/ui/separator.tsx.
class AppCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;

  const AppCard({super.key, required this.children, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class AppSeparator extends StatelessWidget {
  const AppSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(height: 1, color: colors.border);
  }
}

class SettingsRow extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onPressed;

  const SettingsRow({super.key, required this.label, this.trailing, this.showChevron = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return InkWell(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: colors.foreground))),
            if (trailing != null) trailing!,
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: colors.mutedForeground),
            ],
          ],
        ),
      ),
    );
  }
}
