import 'package:flutter/material.dart';

/// Port of components/AppSplashScreen.tsx — shown while the initial
/// Supabase session check resolves (see state/session_sync.dart). Uses
/// hardcoded white/black backgrounds matching the native splash exactly,
/// not the theme's `background` token (which can be an off-white/off-black
/// shade and would show as a visible flash at the handoff) — same
/// reasoning as the RN component.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Icon(Icons.shield_outlined, size: 96, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }
}
