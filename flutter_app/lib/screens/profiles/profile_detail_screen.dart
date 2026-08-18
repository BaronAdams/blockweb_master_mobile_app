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
import '../../widgets/app_icon.dart';
import '../../widgets/danger_button.dart';
import '../../widgets/entry_icon.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_title.dart';

/// Port of app/profiles/[id].tsx, redesigned after the chrome extension's
/// dashboard/pages/TimerProfileDetail.tsx: header with back/edit/delete +
/// active toggle, a consumption card, the interval rules (interval type
/// only), then the watched apps (real installed-app icons) and watched
/// sites (favicons) as two separate lists instead of one combined
/// "watchedSites" text list — matches how the profile actually targets
/// both apps and sites, not just sites.
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
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('profiles', key, vars: vars);
    String ts(String key) => i18n.t('strictMode', key);
    String tc(String key) => i18n.t('common', key);
    String tb(String key) => i18n.t('blockLists', key);
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
    final remainingMinutesRaw = limitMinutes - usedMinutes;
    final remainingMinutes = remainingMinutesRaw < 0 ? 0.0 : remainingMinutesRaw;
    final strictModeActive = store.strictMode.isActive;

    final installedApps = ref.watch(installedAppsProvider).value ?? const [];
    String resolveAppLabel(String packageName) {
      for (final app in installedApps) {
        if (app.packageName == packageName) return app.appName;
      }
      return packageName;
    }

    String? resolveAppIcon(String packageName) {
      for (final app in installedApps) {
        if (app.packageName == packageName) return app.icon;
      }
      return null;
    }

    final monitoredCount = profile.apps.length + profile.websites.length + profile.keywords.length;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => context.canPop() ? context.pop() : context.go('/blocklists'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: colors.card, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Icon(Icons.arrow_back_rounded, size: 16, color: colors.mutedForeground),
                  ),
                ),
                const SizedBox(width: 12),
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
                      Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.foreground)),
                      Text(t(meta.labelKey), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/profiles/${profile!.id}/edit'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: colors.card, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Icon(Icons.edit_outlined, size: 15, color: colors.mutedForeground),
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
                        Text(t('detailsStats'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.foreground)),
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
                  if (profile.activeDays != null && profile.activeDays!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('${t('appDays')}: ${profile.activeDays!.map((d) => tc(d.labelKey)).join(', ')}',
                        style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
                  ],
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
                  Text(profile.intervalConfig!.days.map((d) => tc(d.labelKey)).join(', '),
                      style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                ],
              ),
            const SizedBox(height: 20),
            Text(t('monitored', {'n': monitoredCount}).toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: colors.mutedForeground)),
            const SizedBox(height: 8),
            AppCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionTitle(t('watchedApps')),
                ),
                if (profile.apps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(t('noSite'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                  )
                else
                  for (int i = 0; i < profile.apps.length; i++) ...[
                    if (i > 0) const AppSeparator(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          AppIcon(appName: resolveAppLabel(profile.apps[i]), icon: resolveAppIcon(profile.apps[i]), size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(resolveAppLabel(profile.apps[i]),
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: colors.foreground)),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SectionTitle(t('watchedSites')),
                ),
                if (profile.websites.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(t('noSite'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                  )
                else
                  for (int i = 0; i < profile.websites.length; i++) ...[
                    if (i > 0) const AppSeparator(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          EntryIcon(name: profile.websites[i], type: EntryIconType.site, color: colors.mutedForeground, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(profile.websites[i],
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: colors.foreground)),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
            if (profile.keywords.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionTitle(tb('blockedKeywords')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final keyword in profile.keywords)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: colors.background, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(999)),
                          child: Text(keyword, style: TextStyle(fontSize: 12, color: colors.foreground)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
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
