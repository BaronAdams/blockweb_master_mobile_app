import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Port of components/SubScreenHeader.tsx.
class SubScreenHeader extends StatelessWidget {
  final String title;
  final Widget? right;

  const SubScreenHeader({super.key, required this.title, this.right});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.chevron_left_rounded, size: 24, color: colors.foreground),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.foreground)),
          ),
          if (right != null) right!,
        ],
      ),
    );
  }
}
