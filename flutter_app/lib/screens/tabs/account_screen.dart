import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/i18n_service.dart';
import '../../models/app_models.dart';
import '../../models/limits.dart';
import '../../native/supabase_client.dart';
import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/danger_button.dart';
import '../../widgets/section_title.dart';

const Map<UserPlan, ({String labelKey, Color color})> _planBadge = {
  UserPlan.free: (labelKey: 'free', color: Color(0xFFA1A1AA)),
  UserPlan.monthly: (labelKey: 'monthly', color: Color(0xFFFCD34D)),
  UserPlan.yearly: (labelKey: 'yearly', color: Color(0xFFFCD34D)),
  UserPlan.lifetime: (labelKey: 'lifetime', color: Color(0xFF6EE7B7)),
};

/// Port of app/(tabs)/account.tsx.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmText,
    required VoidCallback onConfirm,
  }) async {
    final colors = AppTheme.colorsOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(title, style: TextStyle(color: colors.foreground)),
        content: Text(description, style: TextStyle(color: colors.mutedForeground)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText, style: const TextStyle(color: Color(0xFFF43F5E))),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('account', key);
    String tc(String key) => i18n.t('common', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    Future<void> onLogout() async {
      try {
        await supabase.auth.signOut();
      } catch (_) {}
      notifier.logout();
    }

    final user = store.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colors.card,
                    child: Icon(Icons.person_outline_rounded, size: 28, color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 12),
                  Text(t('guestTitle'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.foreground)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 280,
                    child: Text(t('guestDesc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, height: 1.3, color: colors.mutedForeground)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.primaryForeground,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(t('signInCta')),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _AppearanceSection(t: t),
              const SizedBox(height: 20),
              _LanguageSection(t: t),
            ],
          ),
        ),
      );
    }

    final initials = (user.username.isNotEmpty ? user.username : user.email).substring(0, 2).toUpperCase();
    final planMeta = _planBadge[store.plan]!;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colors.card,
                  child: Text(initials, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.foreground)),
                ),
                const SizedBox(height: 12),
                Text(user.username, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.foreground)),
                const SizedBox(height: 2),
                Text(user.email, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: planMeta.color.withOpacity(0.1),
                    border: Border.all(color: planMeta.color.withOpacity(0.38)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPremium(store.plan) ? tc('pro') : tc('free').toUpperCase(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: planMeta.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionTitle(t('subscription')),
            AppCard(children: [
              SettingsRow(
                label: t('plan'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: planMeta.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(tc(planMeta.labelKey), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: planMeta.color)),
                ),
              ),
              const AppSeparator(),
              SettingsRow(label: t('subscription'), showChevron: true, onPressed: () => context.push('/pricing')),
            ]),
            const SizedBox(height: 20),
            const SectionTitle('Sécurité'),
            AppCard(children: [
              SettingsRow(label: t('changePassword'), showChevron: true),
              const AppSeparator(),
              SettingsRow(label: t('changeUsername'), showChevron: true),
            ]),
            const SizedBox(height: 20),
            _AppearanceSection(t: t),
            const SizedBox(height: 20),
            SectionTitle(t('permanentDeletion'), color: const Color(0xFFF43F5E)),
            DangerButton(
              label: t('signOut'),
              icon: Icons.logout_rounded,
              onPressed: () => _confirm(
                context,
                title: t('signOut'),
                description: t('signOutConfirm'),
                confirmText: t('signOut'),
                onConfirm: onLogout,
              ),
            ),
            const SizedBox(height: 10),
            DangerButton(
              label: t('deleteMyAccount'),
              icon: Icons.delete_outline_rounded,
              onPressed: () => _confirm(
                context,
                title: t('deleteMyAccount'),
                description: t('deleteDesc'),
                confirmText: t('permanentDelete'),
                // Account deletion itself isn't wired to a backend call yet
                // (the RN app doesn't have one either — its onConfirm is
                // also just `onLogout` today); matching that as-is rather
                // than inventing new backend behavior.
                onConfirm: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A device preference, not personal account data — shown for guests too.
class _AppearanceSection extends ConsumerWidget {
  final String Function(String) t;
  const _AppearanceSection({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    const options = [
      (mode: ThemeMode.system, labelKey: 'themeSystem', icon: Icons.smartphone_outlined),
      (mode: ThemeMode.light, labelKey: 'themeLight', icon: Icons.wb_sunny_outlined),
      (mode: ThemeMode.dark, labelKey: 'themeDark', icon: Icons.dark_mode_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t('appearance')),
        AppCard(
          children: [
            for (final (index, option) in options.indexed) ...[
              if (index > 0) const AppSeparator(),
              SettingsRow(
                label: t(option.labelKey),
                onPressed: () => notifier.setThemeMode(option.mode),
                trailing: Icon(option.icon, size: 18, color: themeMode == option.mode ? colors.primary : colors.mutedForeground),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Two choices only, per product decision: the phone's own language (if we
/// have a translation for it), or English.
class _LanguageSection extends ConsumerWidget {
  final String Function(String) t;
  const _LanguageSection({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    final options = <(LanguagePreference, String)>[
      if (I18nService.deviceLanguage != 'en')
        (
          LanguagePreference.device,
          '${t('languageDevice')} — ${I18nService.languageNames[I18nService.deviceLanguage] ?? I18nService.deviceLanguage}',
        ),
      (LanguagePreference.en, I18nService.languageNames['en']!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(t('language')),
        AppCard(
          children: [
            for (final (index, option) in options.indexed) ...[
              if (index > 0) const AppSeparator(),
              SettingsRow(
                label: option.$2,
                onPressed: () async {
                  notifier.setLanguagePreference(option.$1);
                  await ref.read(i18nProvider).setLanguage(option.$1 == LanguagePreference.en ? 'en' : I18nService.deviceLanguage);
                },
                trailing: store.languagePreference == option.$1
                    ? Icon(Icons.check_rounded, size: 18, color: colors.primary)
                    : null,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
