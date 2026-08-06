import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/i18n_service.dart';

/// Phase-1 scope only: proves the persistence pattern (shared_preferences,
/// mirroring the RN app's AsyncStorage-backed Zustand `persist` middleware)
/// with the one piece of state that's global regardless of which screen is
/// active — theme mode. The full store (store/useAppStore.ts: blocklists,
/// profiles, strict mode, analytics, plan/limits) is intentionally NOT
/// ported here — it gets built alongside the screens that actually read
/// and mutate it, in the screen-porting phase, so it isn't guessed at and
/// then redone.

const _themeModePrefsKey = 'blockweb_master.theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModePrefsKey);
    switch (stored) {
      case 'light':
        state = ThemeMode.light;
      case 'dark':
        state = ThemeMode.dark;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePrefsKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Overridden in main() once I18nService.init() resolves, so every widget
/// can `ref.watch(i18nProvider)` the same way RN screens call
/// `useTranslation(namespace)`.
final i18nProvider = ChangeNotifierProvider<I18nService>(
  (ref) => throw UnimplementedError('i18nProvider must be overridden in main() after I18nService.init()'),
);
