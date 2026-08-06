import 'package:flutter/material.dart';

/// Direct port of theme/colors.ts — keep these two files in sync by hand
/// until the screen-porting phase removes the RN app. Note the app's own
/// convention: `primary` is near-black in light mode and amber in dark
/// mode (not a mistake — matches the icon/splash branding already shipped).
class AppColors {
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;

  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
  });

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF000000),
    card: Color(0xFFF2F2F7),
    cardForeground: Color(0xFF000000),
    popover: Color(0xFFF2F2F7),
    popoverForeground: Color(0xFF000000),
    primary: Color(0xFF18181B),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFF2F2F7),
    secondaryForeground: Color(0xFF18181B),
    muted: Color(0x33787880),
    mutedForeground: Color(0xFF71717A),
    accent: Color(0xFFF2F2F7),
    accentForeground: Color(0xFF18181B),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFC6C6C8),
    input: Color(0xFFE4E4E7),
    ring: Color(0xFFA1A1AA),
  );

  static const dark = AppColors(
    background: Color(0xFF09090B),
    foreground: Color(0xFFF4F4F5),
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFF4F4F5),
    popover: Color(0xFF18181B),
    popoverForeground: Color(0xFFF4F4F5),
    primary: Color(0xFFF59E0B),
    primaryForeground: Color(0xFF09090B),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFA1A1AA),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFF71717A),
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFF4F4F5),
    destructive: Color(0xFFF43F5E),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF27272A),
    input: Color(0xFF18181B),
    ring: Color(0xFFF59E0B),
  );
}
