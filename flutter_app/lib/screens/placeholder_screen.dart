import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Stand-in body for every route until its real RN screen is ported
/// (phase 2). Exists so the router/navigation/theming can be exercised
/// and built end to end right now, instead of waiting for every screen to
/// be finished first.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: colors.foreground)),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          '$title\n(not yet ported)',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.mutedForeground, fontSize: 15),
        ),
      ),
    );
  }
}
