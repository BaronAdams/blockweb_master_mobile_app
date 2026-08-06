import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_models.dart';
import '../../models/profile_types.dart';
import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../state/installed_apps.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_card.dart';
import '../../widgets/danger_button.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_title.dart';

/// Port of app/profiles/[id].tsx. Resolves profile.apps (package names) to
/// display labels via installedAppsProvider, same as the RN screen's
/// useInstalledApps() — falls back to the raw package name when a lookup
/// misses (e.g. the app was uninstalled since it was added to the profile).
class ProfileDetailScreen extends ConsumerWidget {
  final String id;
  const ProfileDetailScreen({super.key, required this.id});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String Function(String) t, String Function(String) tc) async {
    final colors = AppTheme.colorsOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(t('deleteProfile'), style: TextStyle(color: colors.foreground)),
        content: Text(t('deleteDesc'), style: TextStyle(color: colors.mutedForeground)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(tc('delete'), style: const TextStyle(color: Color(0xFFF43F5E))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(appStoreProvider.notifier).deleteProfile(id);
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('profiles', key);
    String ts(String key) => i18n.t('strictMode', key);
    String tc(String key) => i18n.t('common', key);
    final store = ref.watch(appStoreProvider);
    final notifier = ref.read(appStoreProvider.notifier);

    LimiterProfile? profile;
    for (final p in store.limiterProfiles) {
      if (p.id == id) {
        profile = p;
        break;
      }
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Text(t('profileNotExists'), style: TextStyle(color: colors.mutedForeground)),
        ),
      );
    }

    final meta = profileTypeMeta[profile.type]!;
    final usedMinutes = switch (profile.type) {
      LimiterType.daily => (profile.dailyUsedMinutes ?? 0).toDouble(),
      LimiterType.hourly => (profile.hourlyUsedMinutes ?? 0).toDouble(),
      LimiterType.weekly => (profile.weeklyUsedMinutes ?? 0).toDouble(),
      LimiterType.interval => 0.0,
    };
    final limitMinutes = switch (profile.type) {
      LimiterType.daily => (profile.dailyLimitMinutes ?? 0).toDouble(),
      LimiterType.hourly => (profile.hourlyLimitMinutes ?? 0).toDouble(),
      LimiterType.weekly => (profile.weeklyLimitMinutes ?? 0).toDouble(),
      LimiterType.interval => 0.0,
    };
    final progressValue = limitMinutes > 0 ? (usedMinutes / limitMinutes * 100).clamp(0, 100).toDouble() : 0.0;
    final hasBudget = profile.type != LimiterType.interval;
    final remainingMinutes = (limitMinutes - usedMinutes).clamp(0, double.infinity);
    final strictModeActive = store.strictMode.isActive;

    final installedApps = ref.watch(installedAppsProvider).value ?? const [];
    String resolveAppLabel(String packageName) {
      for (final app in installedApps) {
        if (app.packageName == packageName) return app.appName;
      }
      return packageName;
    }

    final watchedNames = [
      ...profile.apps.map(resolveAppLabel),
      ...profile.websites,
      ...profile.keywords,
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: meta.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Icon(meta.icon, size: 22, color: meta.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.foreground)),
                      Text(t(meta.labelKey), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Statut', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.foreground)),
                        Text(profile.isActive ? ts('activeShrt') : t('waiting'),
                            style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
                      ],
                    ),
                    Switch(
                      value: profile.isActive,
                      onChanged: strictModeActive ? null : (_) => notifier.activateProfile(profile!.id),
                      activeColor: colors.primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasBudget)
              AppCard(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionTitle(t('consumption')),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${formatMinutes(usedMinutes)} ${t('timeUsed').toLowerCase()}',
                          style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colors.mutedForeground)),
                      Text(formatMinutes(limitMinutes), style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colors.mutedForeground)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppProgressBar(value: progressValue, height: 10),
                  const SizedBox(height: 10),
                  Text('${t('remaining')}: ${formatMinutes(remainingMinutes)}',
                      style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
                ],
              )
            else if (profile.intervalConfig != null)
              AppCard(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionTitle(t('timeRanges')),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: meta.color),
                      const SizedBox(width: 8),
                      Text('${profile.intervalConfig!.startTime}–${profile.intervalConfig!.endTime}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.foreground)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(profile.intervalConfig!.days.map((d) => d.name).join(', '),
                      style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                ],
              ),
            const SizedBox(height: 20),
            AppCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionTitle(t('watchedSites')),
                ),
                if (watchedNames.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(t('noSite'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                  )
                else
                  for (int i = 0; i < watchedNames.length; i++) ...[
                    if (i > 0) const AppSeparator(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(watchedNames[i], style: TextStyle(fontSize: 14, color: colors.foreground)),
                    ),
                  ],
              ],
            ),
            const SizedBox(height: 20),
            DangerButton(
              label: strictModeActive ? t('strictBlocked') : t('deleteProfile'),
              icon: Icons.delete_outline_rounded,
              onPressed: strictModeActive ? null : () => _confirmDelete(context, ref, t, tc),
            ),
          ],
        ),
      ),
    );
  }
}
