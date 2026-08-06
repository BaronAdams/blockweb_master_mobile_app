import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_models.dart';
import '../../models/profile_types.dart';
import '../../state/app_settings.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/progress_bar.dart';

/// Port of app/(tabs)/profiles.tsx.
class ProfilesListScreen extends ConsumerWidget {
  const ProfilesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('profiles', key, vars: vars);
    final profiles = ref.watch(appStoreProvider).limiterProfiles;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('title'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colors.foreground)),
                      OutlinedButton(
                        onPressed: () => context.push('/profiles/create'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          foregroundColor: colors.foreground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(t('create')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: profiles.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(t('noProfileDesc'),
                                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 40),
                            itemCount: profiles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final profile = profiles[index];
                              return _ProfileCard(profile: profile, onTap: () => context.push('/profiles/${profile.id}'));
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final LimiterProfile profile;
  final VoidCallback onTap;
  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key, [Map<String, dynamic>? vars]) => i18n.t('profiles', key, vars: vars);
    String ts(String key) => i18n.t('strictMode', key);

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

    final count = profile.apps.length + profile.websites.length + profile.keywords.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(21, 16, 16, 16),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(left: -21, top: -16, bottom: -16, width: 3, child: Container(color: meta.color)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: meta.color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Icon(meta.icon, size: 16, color: meta.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.foreground)),
                          Text('${t('getSiteCount', {
                                'count': count
                              })} · ${t(meta.labelKey)}', style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(999)),
                      child: Text(profile.isActive ? ts('activeShrt') : t('waiting'),
                          style: TextStyle(fontSize: 11, color: colors.foreground)),
                    ),
                  ],
                ),
                if (hasBudget) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatMinutes(usedMinutes), style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: colors.mutedForeground)),
                      Text(formatMinutes(limitMinutes), style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: colors.mutedForeground)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppProgressBar(value: progressValue),
                ],
                if (profile.type == LimiterType.interval && profile.intervalConfig != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: colors.mutedForeground),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${profile.intervalConfig!.startTime}–${profile.intervalConfig!.endTime} · '
                          '${profile.intervalConfig!.days.map((d) => d.name).join(' ')}',
                          style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
