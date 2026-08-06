import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FaqItem {
  final String id;
  final String question;
  final String answer;
  const FaqItem({required this.id, required this.question, required this.answer});
}

/// Port of components/FaqAccordion.tsx — uses Flutter's built-in
/// ExpansionTile rather than a hand-rolled Reanimated accordion; same
/// expand/collapse behavior, native platform look instead of a pixel
/// match of the RN component's custom animation.
class FaqAccordion extends StatelessWidget {
  final List<FaqItem> items;
  const FaqAccordion({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: colors.border),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) Container(height: 1, color: colors.border),
              ExpansionTile(
                title: Text(items[i].question,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.foreground)),
                iconColor: colors.primary,
                collapsedIconColor: colors.mutedForeground,
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(items[i].answer, style: TextStyle(fontSize: 12, height: 1.4, color: colors.mutedForeground)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
