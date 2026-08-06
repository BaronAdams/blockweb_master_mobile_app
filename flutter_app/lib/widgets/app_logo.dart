import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Placeholder for components/AppLogo.tsx — a plain themed icon mark until
/// the real branded assets are ported over. Kept as a single small widget
/// so swapping in the real logo image later touches one file.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Icon(Icons.shield_outlined, color: colors.primary, size: size * 0.5),
    );
  }
}
