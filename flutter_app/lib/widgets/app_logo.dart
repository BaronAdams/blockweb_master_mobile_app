import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Port of components/AppLogo.tsx — the icon + "BlockWeb Master" wordmark
/// lockup, shared by AppHeader (the tab bar) and any screen that needs the
/// same brand mark standalone (e.g. centered above the login/register form).
class AppLogo extends StatelessWidget {
  /// Icon box side, in logical px. The wordmark and inner image scale off it.
  final double size;
  const AppLogo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final imageSize = size * 0.82;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(size * 0.27),
            border: Border.all(color: colors.primary.withOpacity(0.25)),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/shield_foreground.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: 12),
        Text(
          'BlockWeb Master',
          style: GoogleFonts.montserrat(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
