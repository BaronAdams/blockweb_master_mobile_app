import 'dart:convert';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Port of components/AppIcon.tsx. `icon` here is a "data:image/png;base64,..."
/// URI built natively (see BlockerBridge.kt), not a file:// path — decoded
/// directly rather than loaded as a file/network image.
class AppIcon extends StatelessWidget {
  final String appName;
  final String? icon;
  final double size;

  const AppIcon({super.key, required this.appName, this.icon, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final radius = BorderRadius.circular(size * 0.22);

    final base64Data = icon != null && icon!.startsWith('data:image')
        ? icon!.substring(icon!.indexOf(',') + 1)
        : null;

    if (base64Data != null) {
      try {
        final bytes = base64Decode(base64Data);
        return ClipRRect(
          borderRadius: radius,
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(colors, radius),
          ),
        );
      } catch (_) {
        return _fallback(colors, radius);
      }
    }

    return _fallback(colors, radius);
  }

  Widget _fallback(AppColors colors, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.background, borderRadius: radius, border: Border.all(color: colors.border)),
      alignment: Alignment.center,
      child: Text(
        appName.isNotEmpty ? appName[0].toUpperCase() : '?',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: size * 0.4, color: colors.foreground),
      ),
    );
  }
}
