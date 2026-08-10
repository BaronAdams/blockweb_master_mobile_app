import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Port of components/AppHeader.tsx.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
      // 44 matches AppLogo's own default (and AppHeader.tsx, which doesn't
      // override it) — was 36, noticeably smaller than the RN header.
      child: const Row(children: [AppLogo(size: 44)]),
    );
  }
}
