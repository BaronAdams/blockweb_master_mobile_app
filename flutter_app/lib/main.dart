import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/i18n_service.dart';
import 'native/supabase_client.dart';
import 'router/app_router.dart';
import 'state/app_settings.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final i18n = I18nService();
  await i18n.init();
  await initSupabase();

  runApp(
    ProviderScope(
      overrides: [
        i18nProvider.overrideWith((ref) => i18n),
      ],
      child: const BlockWebMasterApp(),
    ),
  );
}

class BlockWebMasterApp extends ConsumerWidget {
  const BlockWebMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // AnimatedBuilder, not ref.watch, on purpose: I18nService is a
    // ChangeNotifier consumed by plain (non-Riverpod) descendants through
    // AppTheme-style InheritedWidgets elsewhere — this keeps main.dart from
    // needing to know which screens are Riverpod- vs InheritedWidget-based.
    ref.watch(i18nProvider);

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedBrightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    final colors = resolvedBrightness == Brightness.dark ? AppColors.dark : AppColors.light;

    return AppTheme(
      colors: colors,
      brightness: resolvedBrightness,
      child: MaterialApp.router(
        title: 'BlockWeb Master',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: buildMaterialTheme(AppColors.light, Brightness.light),
        darkTheme: buildMaterialTheme(AppColors.dark, Brightness.dark),
        routerConfig: appRouter,
      ),
    );
  }
}
