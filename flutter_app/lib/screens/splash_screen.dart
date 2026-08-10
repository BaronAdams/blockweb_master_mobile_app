import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_settings.dart';

/// Port of components/AppSplashScreen.tsx — shown while the initial
/// Supabase session check resolves (see state/session_sync.dart). Uses
/// hardcoded white/black backgrounds matching the native splash exactly,
/// not the theme's `background` token (which can be an off-white/off-black
/// shade and would show as a visible flash at the handoff) — same
/// reasoning as the RN component. Follows the user's chosen theme mode
/// (light/dark/system), not just the raw platform brightness — "system"
/// is the only case where those two are the same thing.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = switch (themeMode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/shield_foreground.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
