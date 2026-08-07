import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/i18n_service.dart';
import 'native/app_monitor.dart';
import 'native/supabase_client.dart';
import 'router/app_router.dart';
import 'state/app_settings.dart';
import 'state/session_sync.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final i18n = I18nService();
  await i18n.init();
  await initSupabase();

  // A plain ProviderContainer (rather than letting ProviderScope create one
  // implicitly) so session sync — which needs to read/write providers —
  // can be kicked off here, before the first frame, the same way
  // app/_layout.tsx's RootLayoutNav effect runs on mount in the RN app.
  final container = ProviderContainer(
    overrides: [i18nProvider.overrideWith((ref) => i18n)],
  );
  // Not awaited: the router's redirect logic shows a splash screen via
  // sessionLoadedProvider until this resolves, so the first frame doesn't
  // need to wait on it.
  SessionSyncService.init(container);
  // Bridges blocklists/analytics to the native blocking engine — see
  // native/app_monitor.dart's doc comment for why this is load-bearing
  // (without it, native never learns the current blocklists and Dart never
  // pulls real usage stats back).
  AppMonitorService.init(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
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
    final i18n = ref.watch(i18nProvider);
    final router = ref.watch(appRouterProvider);

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedBrightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    final colors = resolvedBrightness == Brightness.dark ? AppColors.dark : AppColors.light;

    // RTL for Arabic — port of app/_layout.tsx's I18nManager.forceRTL call.
    // Flutter doesn't need an app restart for this the way RN does: wrapping
    // with Directionality applies it immediately.
    final textDirection = i18n.language == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return AppTheme(
      colors: colors,
      brightness: resolvedBrightness,
      child: MaterialApp.router(
        title: 'BlockWeb Master',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: buildMaterialTheme(AppColors.light, Brightness.light),
        darkTheme: buildMaterialTheme(AppColors.dark, Brightness.dark),
        routerConfig: router,
        // MaterialApp determines text direction from Localizations, which
        // this app doesn't configure (it uses I18nService, not Flutter's
        // localization system) — `builder` is the documented way to inject
        // a Directionality for the routed content itself instead of one
        // that silently gets overridden by MaterialApp's own default.
        builder: (context, child) => Directionality(textDirection: textDirection, child: child!),
      ),
    );
  }
}
