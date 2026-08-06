import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Exposes the active AppColors palette to the widget tree without every
/// screen needing a Riverpod watch just to read a color — mirrors the RN
/// app's useColor() hook (theme/theme-provider.tsx), which reads off React
/// context the same way.
class AppTheme extends InheritedWidget {
  final AppColors colors;
  final Brightness brightness;

  const AppTheme({
    super.key,
    required this.colors,
    required this.brightness,
    required super.child,
  });

  static AppColors colorsOf(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(theme != null, 'AppTheme.colorsOf() called with no AppTheme ancestor');
    return theme!.colors;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) =>
      oldWidget.colors != colors || oldWidget.brightness != brightness;
}

ThemeData buildMaterialTheme(AppColors c, Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      secondary: c.secondary,
      onSecondary: c.secondaryForeground,
      error: c.destructive,
      onError: c.destructiveForeground,
      surface: c.card,
      onSurface: c.cardForeground,
    ),
    dividerColor: c.border,
    fontFamily: 'system-ui',
    useMaterial3: true,
  );
}
